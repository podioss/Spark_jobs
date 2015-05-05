#datasets for clusters 5 10 15 20
for i in 5 10 15 20 
do
	./genim.py -n 10000 -d 2 -c $i -o n10000/d2/c${i}
done
