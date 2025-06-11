#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# 결과 디렉토리 생성
mkdir -p "${SCRIPT_DIR}/A" "${SCRIPT_DIR}/B" "${SCRIPT_DIR}/C" "${SCRIPT_DIR}/D"

# Branch Predictor 종류
bps=(BPB AT NT BTFNT)

# 동시에 실행할 그룹 크기 (세트 단위)
GROUP_SIZE=12
set_count=0

for l1_cache_size in 128 256 512 1024 2048 4096 8192; do
    echo -e "${GREEN}Starting simulations for l1.cacheSize=${l1_cache_size}...${NC}"

    for l1_block_size in 4 8 16 32 64 128 256 512 1024 2048 4096 8192; do
        if [ $l1_block_size -gt $l1_cache_size ]; then continue; fi

        for l1_associativity in 2 4 8; do
            total_cache_required=$(( l1_block_size * l1_associativity ))
            if [ $total_cache_required -le $l1_cache_size ]; then
                for bp in "${bps[@]}"; do
                    config_file="${SCRIPT_DIR}/configuration.cfg"

                    cat > "$config_file" <<EOF
configA
l1.cacheSize=${l1_cache_size}
l1.blockSize=${l1_block_size}
l1.associativity=${l1_associativity}
l2.cacheSize=2048
l2.blockSize=32
l2.associativity=4
bp=${bp}
configB
l1.cacheSize=${l1_cache_size}
l1.blockSize=${l1_block_size}
l1.associativity=${l1_associativity}
l2.cacheSize=2048
l2.blockSize=32
l2.associativity=4
bp=${bp}
configC
l1.cacheSize=${l1_cache_size}
l1.blockSize=${l1_block_size}
l1.associativity=${l1_associativity}
l2.cacheSize=2048
l2.blockSize=32
l2.associativity=4
bp=${bp}
configD
l1.cacheSize=${l1_cache_size}
l1.blockSize=${l1_block_size}
l1.associativity=${l1_associativity}
l2.cacheSize=2048
l2.blockSize=32
l2.associativity=4
bp=${bp}
EOF

              #      echo -e "${GREEN}Preparing set: l1.cacheSize=${l1_cache_size}, blockSize=${l1_block_size}, associativity=${l1_associativity}, bp=${bp}...${NC}"

                    # A
                    "${SCRIPT_DIR}/Simulator" "${SCRIPT_DIR}/benchmark/A.riscv" -a > "${SCRIPT_DIR}/A/A_configA_${l1_cache_size}_${l1_block_size}_${l1_associativity}_${bp}.txt" &
          #          echo -e "${BLUE}Results saved to A/A_configA_${l1_cache_size}_${l1_block_size}_${l1_associativity}_${bp}.txt${NC}"

                    # B
                    "${SCRIPT_DIR}/Simulator" "${SCRIPT_DIR}/benchmark/B.riscv" -b > "${SCRIPT_DIR}/B/B_configB_${l1_cache_size}_${l1_block_size}_${l1_associativity}_${bp}.txt" &
           #         echo -e "${BLUE}Results saved to B/B_configB_${l1_cache_size}_${l1_block_size}_${l1_associativity}_${bp}.txt${NC}"

                    # C
                    "${SCRIPT_DIR}/Simulator" "${SCRIPT_DIR}/benchmark/C.riscv" -c > "${SCRIPT_DIR}/C/C_configC_${l1_cache_size}_${l1_block_size}_${l1_associativity}_${bp}.txt" &
            #        echo -e "${BLUE}Results saved to C/C_configC_${l1_cache_size}_${l1_block_size}_${l1_associativity}_${bp}.txt${NC}"

                    # D
                    "${SCRIPT_DIR}/Simulator" "${SCRIPT_DIR}/benchmark/D.riscv" -d > "${SCRIPT_DIR}/D/D_configD_${l1_cache_size}_${l1_block_size}_${l1_associativity}_${bp}.txt" &
             #       echo -e "${BLUE}Results saved to D/D_configD_${l1_cache_size}_${l1_block_size}_${l1_associativity}_${bp}.txt${NC}"

                    # set_count 증가
                    ((set_count++))

                    if [ "$set_count" -ge "$GROUP_SIZE" ]; then
                        wait
                        set_count=0
                        echo -e "${GREEN}Batch of ${GROUP_SIZE} sets (64 simulations) completed.${NC}\n"
                    fi
                done
            fi
        done
    done

    echo -e "${GREEN}All simulations completed for l1.cacheSize=${l1_cache_size}.${NC}\n"
done

# 남은 세트 처리
wait
echo -e "${GREEN}All simulations for all cache sizes completed.${NC}"
