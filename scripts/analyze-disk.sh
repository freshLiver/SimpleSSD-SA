#!/bin/bash
function analyze() {
    # usage: analyze $file $name
    BEG_TIME=$(grep "HIL: Runtime startSlet" "$1" | grep -oP "^\d+")
    BEG_TIME=${BEG_TIME:-0}
    CSV_DATA=$(grep "PALOLD: READ LCA" "$1" | awk "
        BEGIN { CNT = 0;}
        {
            addr = \$5
            stime = \$7-$BEG_TIME
            etime = \$11-$BEG_TIME
            duration = \$9
            if (duration > 800000 && \$7-$BEG_TIME > 0) {
                #printf \"$2,%d,%d,%d\n\", CNT,addr,stime
                #printf \"$2,%d,%d,%d\n\", CNT,addr,etime
                printf \"$2,%d,%d\n\", CNT,addr
                CNT += 1
            }
        }
    ")
    echo "$CSV_DATA"
}

workloads=(
    # ALIAS PATH
    "gr-4k2k-host grep-host-4kx2k.log"
    "gr-4k2k-f-p grep-fsa-4kx2k.log"
    "gr-4k2k-f-np grep-fsa-4kx2k-nopft.log"
)

NAMES=()
DATA=()
for work in "${workloads[@]}"; do
    read name file <<< "$work"
    NAMES+=("$name")
    DATA+="$(analyze "$file" "$name")"$'\n\n'
done

# echo "${NAMES[@]}"
echo "$DATA"
exit

python3 - <<END
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
from io import StringIO

w_column = "WORKLOAD"
x_column = "CNT"
y_column = "TIME"
y0_column = "STIME"
y1_column = "ETIME"

csv_data = StringIO(f"""{w_column},{x_column},{y_column},{y0_column},{y1_column}
${DATA}""")
data = pd.read_csv(csv_data)

# 檢查指定的欄位是否存在
if x_column not in data.columns or y_column not in data.columns:
    print(f"Error: columns '{x_column}' or '{y_column}' not found.")
    print(data.columns)
    exit(1)

# 繪製散佈圖
plt.figure(figsize=(8, 6))

for i in range(len(data[x_column])):
    print(f"{data[x_column][i]} {data[y0_column][i]} {data[y1_column][i]}")
    plt.plot([data[x_column][i], data[x_column][i]],
             [data[y0_column][i], data[y1_column][i]],
             marker='', label=f'CNT {data[x_column][i]}')

# plt.scatter(data[x_column], data[y_column], alpha=0.7)

plt.xlabel(x_column)
plt.ylabel(y_column)
plt.title(f"Scatter Plot of {x_column} vs {y_column}")

# 禁用 Y 軸科學記號顯示
ax = plt.gca()  # 獲取當前軸對象
ax.ticklabel_format(style='plain', axis='y')
ax.yaxis.set_major_formatter(FuncFormatter(lambda x, _: f'{x / 1e6:.0f}'))

plt.grid(True)
plt.show()
END

exit

function filter_data() {
    result=$(cat "$1" | awk "
    BEGIN {
        CNT = 0;
    }

    NR > 1 {
        if (\$0 ~ /^[0-9]+\.[0-9]+ \w+( (\+ )?0x[0-9a-fA-F]+){2}( [\w]+)?/) {
            time = \$1 * 1e6
            type = \$2
            offset = strtonum(\$3)
            size = strtonum(\$5)

            if (type == \"R\")
                printf \"$2,%d,%d,%s,%d,%d\n\", CNT, time, type, offset, size, sum
            CNT += 1
        }
    }")
    echo "$result"
}

workloads=(
    # ALIAS PATH
    "host-1024x2000 logs-sa/2410/grep-many-1k-host-pft-1isc/1024-x2000-pft-1isc/29-135512.sim.input"
    "slet-1024x2000 logs-sa/2410/grep-many-1k-slet-pft-1isc/x2000-pft-1isc/28-191114.sim.input"
)

NAMES=()
DATA=()
for work in "${workloads[@]}"; do
    read name file <<< "$work"
    NAMES+=("$name")
    DATA+="$(filter_data "$file" "$name")"$'\n'
done

# echo "${NAMES[@]}"
# echo "$DATA"
# exit

python3 - <<END
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
from io import StringIO

x_column = "TIME (ms)"
y_column = "LBA"

dataset=[[name,None] for name in "${NAMES[@]}".split(" ")]
print(dataset)

raw_data = pd.read_csv(StringIO("""${DATA}"""))
print(raw_data)

for ds in dataset:
    data = raw_data[raw_data[0] == ds[0]]
    print(data)

exit(-1)

csv_data = StringIO(f"""CNT,{x_column},type,{y_column},size
${DATA}""")
data = pd.read_csv(csv_data)

# 檢查指定的欄位是否存在
if x_column not in data.columns or y_column not in data.columns:
    print(f"Error: columns '{x_column}' or '{y_column}' not found.")
    print(data.columns)
    exit(1)

# 繪製散佈圖
plt.figure(figsize=(8, 6))
plt.scatter(data[x_column], data[y_column], s=12, marker='x', alpha=1)

plt.xlabel(x_column)
plt.ylabel(y_column)
plt.title(f"Scatter Plot of {x_column} vs {y_column}")

# 禁用 X 軸科學記號顯示
ax = plt.gca()  # 獲取當前軸對象
ax.ticklabel_format(style='plain', axis='x')
ax.xaxis.set_major_formatter(FuncFormatter(lambda x, _: f'{x / 1000:.0f}'))


plt.grid(True)
plt.show()
END