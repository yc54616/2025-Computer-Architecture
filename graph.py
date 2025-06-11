import os
import re
import matplotlib.pyplot as plt

# 설정
base_dir = "."         # 결과 디렉토리 기준 (현재 디렉토리)
targets = ["A", "B", "C", "D"]
top_n = 10             # 각 Target별 상위 N개의 Benchmark Score 출력

# Benchmark Score 저장 딕셔너리
results = {target: [] for target in targets}

# 결과 파일 탐색
for target in targets:
    results_dir = os.path.join(base_dir, target)
    if not os.path.exists(results_dir):
        print(f"⚠️ 디렉토리 '{results_dir}'가 존재하지 않아 스킵합니다.")
        continue

    for filename in os.listdir(results_dir):
        if filename.endswith(".txt"):
            filepath = os.path.join(results_dir, filename)
            with open(filepath, 'r') as f:
                content = f.read()
                match = re.search(r'Benchmark Score \(bigger is better\): ([0-9.]+)', content)
                if match:
                    score = float(match.group(1))
                    try:
                        tokens = filename.replace(".txt", "").split("_")
                        l1_cache = tokens[2]
                        l1_block = tokens[3]
                        l1_assoc = tokens[4]
                        if "L2" in tokens:
                            l2_cache = tokens[6]
                            l2_block = tokens[7]
                            l2_assoc = tokens[8]
                            bp = tokens[9]
                            label = f"L1:{l1_cache}/{l1_block}/{l1_assoc}\nL2:{l2_cache}/{l2_block}/{l2_assoc}\nBP:{bp}"
                        else:
                            bp = tokens[5]
                            label = f"L1:{l1_cache}/{l1_block}/{l1_assoc}\nBP:{bp}"
                        results[target].append((label, score))
                    except Exception as e:
                        print(f"⚠️ Skipping file {filename} due to parsing error: {e}")

# Benchmark Score가 없는 경우 예외 처리
has_data = False
for target in targets:
    if results[target]:
        has_data = True
        break

if not has_data:
    print("Benchmark Score가 포함된 파일을 찾지 못했습니다.")
    exit(0)

# Subplot 설정
fig, axs = plt.subplots(2, 2, figsize=(18, 10))
axs = axs.flatten()

for idx, target in enumerate(targets):
    if not results[target]:
        axs[idx].set_title(f"{target} 데이터 없음")
        axs[idx].axis('off')
        continue

    sorted_results = sorted(results[target], key=lambda x: x[1], reverse=True)
    top_results = sorted_results[:top_n]

    # Top N 출력
    print(f"\n==== {target} Top {top_n} Benchmark Scores ====")
    for i, (label, score) in enumerate(top_results, 1):
        print(f"{i}. {label}: {score}")

    # 그래프
    labels = [label for label, _ in top_results]
    scores = [score for _, score in top_results]

    bars = axs[idx].bar(range(len(scores)), scores, tick_label=labels, color='skyblue')
    axs[idx].set_xticks(range(len(scores)))
    axs[idx].set_xticklabels(labels, rotation=30, ha='right', fontsize=9)
    axs[idx].set_ylabel('Benchmark Score')
    axs[idx].set_title(f'{target} Top {top_n}')

    # 각 bar 위에 값 표시
    for bar, score in zip(bars, scores):
        axs[idx].text(bar.get_x() + bar.get_width()/2, bar.get_height(),
                      f"{score:.3f}", ha='center', va='bottom', fontsize=8)

plt.tight_layout()
plt.suptitle(f"Top {top_n} Benchmark Scores for A, B, C, D", fontsize=16, y=1.03)
plt.show()

