#!/bin/bash

# Full array of prime numbers
full_primes=(137 139 149 151 157 163 167 173 179 181 
        193 197 199 211 223 227 229 233 239 241 
        251 257 263 269 271 277 281 283 293 307 
        311 313 317 331 337 347 349 353 359 367 
        373 379 383 389 397 401 409 419 421 431 
        433 439 443 449 457 461 463 467 479 487 
        491 499 503 509 521 523 541 547 557 563 
        569 571 577 587 593 599 601 607 613 617 
        619 631 641 643 647 653 659 661 673 677)

# First 10 prime numbers
short_primes=(${full_primes[@]:0:10})

# Parameter array
params=(16 256 65536)

# Step array
steps=(20 30 40 50 60 70 80 90 100 200)

# Create CSV files and add headers
echo "Param,Prime,Step,Compile Time,Setup Time,Witness Time,Proof Time,Verify Time,Proof Size,Proving Key Size,Verification Key Size,Witness Size" > performance_results.csv
echo "Param,Prime,Step,Compile Time,Setup Time,Witness Time,Proof Time,Verify Time,Proof Size,Proving Key Size,Verification Key Size,Witness Size" > whole_journey_results.csv

# Create lists directory
mkdir -p lists

# Generate ucb_$step.zok programs
for step in "${steps[@]}"; do
    cp ucb/ucb.zok ucb/ucb_$step.zok
    sed -i "s/NUMBER/$step/g" ucb/ucb_$step.zok
done

# Main loop
for param in "${params[@]}"; do
    for step in "${steps[@]}"; do
        if [ $step -eq 200 ]; then
            primes=("${full_primes[@]}")
            output_file="performance_results.csv"
        else
            primes=("${short_primes[@]}")
            output_file="whole_journey_results.csv"
        fi

        for prime in "${primes[@]}"; do
            echo "Processing: Parameter=$param, Prime=$prime, Step=$step"

            # Compilation
            start_time=$(date +%s.%N)
            zokrates compile -i ./ucb/ucb_$step.zok
            end_time=$(date +%s.%N)
            compile_time=$(echo "$end_time - $start_time" | bc)

            # Generate proof setup
            start_time=$(date +%s.%N)
            zokrates setup
            end_time=$(date +%s.%N)
            setup_time=$(echo "$end_time - $start_time" | bc)

            # Execute program
            start_time=$(date +%s.%N)
            zokrates compute-witness --verbose -a $prime $param > ./tmp_output.txt
            end_time=$(date +%s.%N)
            witness_time=$(echo "$end_time - $start_time" | bc)

            # Generate proof
            start_time=$(date +%s.%N)
            zokrates generate-proof
            end_time=$(date +%s.%N)
            proof_time=$(echo "$end_time - $start_time" | bc)

            # Verify proof
            start_time=$(date +%s.%N)
            zokrates verify
            end_time=$(date +%s.%N)
            verify_time=$(echo "$end_time - $start_time" | bc)

            # Calculate file sizes
            verification_key_size=$(stat -c%s "verification.key")
            proving_key_size=$(stat -c%s "proving.key")
            proof_size=$(stat -c%s "proof.json")
            witness_size=$(stat -c%s "witness")

            # Add results to the appropriate CSV file
            echo "$param,$prime,$step,$compile_time,$setup_time,$witness_time,$proof_time,$verify_time,$proof_size,$proving_key_size,$verification_key_size,$witness_size" >> $output_file

            # Process and save witness output only when step is 200
            if [ $step -eq 200 ]; then
                awk -v step="$step" '
                BEGIN { print "[" }
                /^\[.*\]$/ {
                    gsub(/\[|\]/, "");
                    n = split($0, a, ",");
                    for (i = 1; i <= n; i++) {
                        if ((i - 1) % step == 0) {
                            if (i > 1) printf "]\n";
                            printf "[";
                        }
                        printf "%s", a[i];
                        if (i % step != 0 && i < n) printf ",";
                    }
                    if (n > 0) print "]";
                }
                END { print "]" }
                ' ./tmp_output.txt > ./lists/output-$step-$param-$prime.txt
            fi

            # Clean up temporary files
            rm -f out out.r1cs out.wtns verification.key proving.key proof.json abi.json witness tmp_output.txt
        done
    done
done

# Clean up ucb_$step.zok programs
for step in "${steps[@]}"; do
    rm -f ucb/ucb_$step.zok
done

echo "All tests completed. Results have been saved to performance_results.csv and whole_journey_results.csv files."