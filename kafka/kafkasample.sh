/opt/kafka/bin/kafka-topics.sh --bootstrap-server k01.example.com:9092 --create --replication-factor 2 --partitions 2 --topic topic1
/opt/kafka/bin/kafka-topics.sh --bootstrap-server k01.example.com:9092 --list
/opt/kafka/bin/kafka-producer-perf-test.sh --topic topic1 --num-records 1000 --throughput 100 --producer-props bootstrap.servers=k01.example.com:9092 --print-metrics --record-size 1024
/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server k02.example.com:9092 --topic topic1
