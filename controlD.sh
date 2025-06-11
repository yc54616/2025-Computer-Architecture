#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Benchmark Score 기준
benchmark_threshold=4.2

# 결과 디렉토리
RESULT_DIR="${SCRIPT_DIR}/D"

# L2 Cache Parameters
L2_CACHE_SIZES=(2048 4096 8192 16384 32768 65536)
L2_BLOCK_SIZES=(4 8 16 32 64 128 256 512 1024)
L2_ASSOCIATIVITIES=(1 2 4 8)

# Branch Predictors
BP_STRATEGIES=(BPB AT NT BTFNT)

# 그룹 개수 설정
GROUP_SIZE=24
group_count=0

echo -e "${GREEN}Filtering results with Benchmark Score > ${benchmark_threshold}...${NC}"

for file in "${RESULT_DIR}"/D_configD_*.txt; do
    benchmark_score=$(grep "Benchmark Score" "$file" | awk -F':' '{print $2}' | tr -d ' ')
    if [[ $(echo "$benchmark_score > $benchmark_threshold" | bc -l) -eq 1 ]]; then
        filename=$(basename "$file")
        l1_cache_size=$(echo "$filename" | cut -d'_' -f3)
        l1_block_size=$(echo "$filename" | cut -d'_' -f4)
        l1_associativity=$(echo "$filename" | cut -d'_' -f5)

        echo -e "${BLUE}Selected: $filename (Score: $benchmark_score)${NC}"

        for l2_cache_size in "${L2_CACHE_SIZES[@]}"; do
            for l2_block_size in "${L2_BLOCK_SIZES[@]}"; do
                if [ $l2_block_size -gt $l2_cache_size ]; then continue; fi

                for l2_associativity in "${L2_ASSOCIATIVITIES[@]}"; do
                    total_cache_required=$(( l2_block_size * l2_associativity ))
                    if [ $total_cache_required -le $l2_cache_size ]; then

                        for bp in "${BP_STRATEGIES[@]}"; do
                            config_file="${SCRIPT_DIR}/configuration.cfg"
                            output_file="${RESULT_DIR}/D_configD_${l1_cache_size}_${l1_block_size}_${l1_associativity}_L2_${l2_cache_size}_${l2_block_size}_${l2_associativity}_${bp}.txt"

                            if [ -f "$output_file" ]; then
                                echo -e "${YELLOW}Skipping existing file: ${output_file}${NC}"
                                continue
                            fi

                            cat > "$config_file" <<EOF
configA
l1.cacheSize=${l1_cache_size}
l1.blockSize=${l1_block_size}
l1.associativity=${l1_associativity}
l2.cacheSize=${l2_cache_size}
l2.blockSize=${l2_block_size}
l2.associativity=${l2_associativity}
bp=${bp}
configB
l1.cacheSize=${l1_cache_size}
l1.blockSize=${l1_block_size}
l1.associativity=${l1_associativity}
l2.cacheSize=${l2_cache_size}
l2.blockSize=${l2_block_size}
l2.associativity=${l2_associativity}
bp=${bp}
configC
l1.cacheSize=${l1_cache_size}
l1.blockSize=${l1_block_size}
l1.associativity=${l1_associativity}
l2.cacheSize=${l2_cache_size}
l2.blockSize=${l2_block_size}
l2.associativity=${l2_associativity}
bp=${bp}
configD
l1.cacheSize=${l1_cache_size}
l1.blockSize=${l1_block_size}
l1.associativity=${l1_associativity}
l2.cacheSize=${l2_cache_size}
l2.blockSize=${l2_block_size}
l2.associativity=${l2_associativity}
bp=${bp}
EOF

                            echo -e "${GREEN}Running: l1.cacheSize=${l1_cache_size}, blockSize=${l1_block_size}, assoc=${l1_associativity}, L2=${l2_cache_size}/${l2_block_size}/${l2_associativity}, bp=${bp}${NC}"

                            "${SCRIPT_DIR}/Simulator" "${SCRIPT_DIR}/benchmark/D.riscv" -d > "$output_file" &

                            ((group_count++))
                            if [ "$group_count" -ge "$GROUP_SIZE" ]; then
                                wait
                                group_count=0
                                echo -e "${GREEN}Batch of $GROUP_SIZE simulations completed.${NC}"
                            fi
                        done
                    fi
                done
            done
        done

        echo -e "${GREEN}Finished all L2 tests for l1.cacheSize=${l1_cache_size}, blockSize=${l1_block_size}, assoc=${l1_associativity}.${NC}\n"
    fi
done

wait
echo -e "${GREEN}All simulations completed.${NC}"

