#!/bin/bash

docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
EOF

docker compose exec -T shard1-1 mongosh --port 27018 --quiet <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1-1:27018" },
        { _id : 1, host : "shard1-2:27021" },
        { _id : 2, host : "shard1-3:27022" },
        { _id : 3, host : "shard1-4:27023" }
      ]
    }
);
EOF







docker compose exec -T shard2-1 mongosh --port 27019 --quiet <<EOF
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 0, host : "shard2-1:27019" },
        { _id : 1, host : "shard2-2:27024" },
        { _id : 2, host : "shard2-3:27025" },
        { _id : 3, host : "shard2-4:27026" }
      ]
    }
);
EOF
#
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard("shard1/shard1-1:27018,shard1-2:27021,shard1-3:27022,shard1-4:27023");
sh.addShard("shard2/shard2-1:27019,shard2-2:27024,shard2-3:27025,shard2-4:27026");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );

use somedb;

for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})

db.helloDoc.countDocuments()

EOF

