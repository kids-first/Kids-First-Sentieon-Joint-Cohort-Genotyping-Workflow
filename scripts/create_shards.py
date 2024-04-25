import sys


def determine_shards_from_fai(fai_file, num_parts, margin):
    with open(fai_file, 'r') as file:
        chromosomes = file.readlines()
    total_length = sum(int(line.strip().split('\t')[1]) for line in chromosomes)
    part_size = total_length // num_parts
    extra = total_length % num_parts
    current_part_size = 0
    current_part_number = 1
    shards_list = [[] for i in range(num_parts)]
    shards_padding_list = [[] for i in range(num_parts)]
    for line in chromosomes:
        parts = line.strip().split('\t')
        chromosome_name = parts[0]
        chromosome_length = int(parts[1])
        start = 1 
        while start <= chromosome_length:
            if current_part_number == num_parts:
                end = chromosome_length + 1
            else:
                end = start + min(part_size - current_part_size + 
                                  (1 if extra > 0 else 0), chromosome_length - start + 1)
                extra -= 1 if start + part_size - current_part_size > chromosome_length and extra > 0 else 0
            current_part_size += end - start
            shards_list[current_part_number-1].append(f'{chromosome_name}:{start}-{end-1}')
            start_padded = max(1, start-margin)
            end_padded = min(end-1+margin, chromosome_length)
            shards_padding_list[current_part_number-1].append(f'{chromosome_name}:{start_padded}-{end_padded}')
            start = end
            if current_part_size >= part_size and current_part_number < num_parts:
                current_part_number += 1
                current_part_size = 0
    name_idx = [str(i).zfill(len(str(len(shards_list)))) for i in range(len(shards_list))]
    with open("bcftools_padded_scatter.tsv", "w") as bcf_out:
        for i in range(len(shards_list)):
            with open(f"shard_interval_{name_idx[i]}.txt", 'w') as fout:
                fout.write(",".join(shards_list[i]))
            for regions in shards_padding_list[i]:
                print("{}\tscatter_{}".format(regions, i), file=bcf_out)


if __name__ == '__main__':
    if len(sys.argv) != 4:
        print("Usage: python partition_genome.py <FAI_FILE> <NUM_PARTS> <PADDING> ")
        sys.exit(1)
    fai_file_path = sys.argv[1]
    number_of_parts = int(sys.argv[2])
    margin = int(sys.argv[3])
    shards_padding_list = determine_shards_from_fai(fai_file_path, number_of_parts, margin)
