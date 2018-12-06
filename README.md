# How to setup Istio 1.0.2 on your OKD 3.10 cluster

## Pre-requisites
- An OKD 3.10 cluster
- Create a user called istio that is able to sudo without a password.
- ansible 2.4.3.0 or later 
- siege load testing tool https://github.com/JoeDog/siege
  which you can install in Mac using 

```
brew install siege
```
- create an alias for ansibile-playbook because it's so cumbersome to type. You can put the following in your $HOME/.bashrc

```
alias ap='ansible-playbook'
```

## Set up
1. Install apache-maven-3.5.4 and place it at /home/istio/apache-maven-3.5.4/
1. Run the ansible script

```
ansible-playbook -i hosts istio.yaml
```

## How to demo
### Demo mutual tls
1. cd to mutual_tls directory

```
cd mutual_tls
```

2. Create the gateway

```
ap 01_create_gateway.yaml
```
You can show the audience what objects were created by running inside the directory:

```
[root@18 mutual_tls]# ./show.sh 01_create_gateway.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: customer-gateway
  namespace: tutorial
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: customer
  namespace: tutorial
spec:
  hosts:
  - "*"
  gateways:
  - customer-gateway
  http:
  - match:
    - uri:
        exact: /
    route:
```
3. Rsh to the customer pod
First identify the pod

```
[root@18 mutual_tls]# oc get pods
NAME                                 READY     STATUS    RESTARTS   AGE
customer-5f76f7f8ff-qkfvv            2/2       Running   0          15m
preference-v1-8486bd5ff5-jszp9       2/2       Running   0          15m
recommendation-v1-768fb5c766-pnb9j   2/2       Running   0          15m
```
Next rsh to the pod.

```
[root@18 mutual_tls]# oc rsh -c istio-proxy customer-5f76f7f8ff-qkfvv
$ 
```
4. Get the pod interface name and ip address

```
$ ifconfig
eth0      Link encap:Ethernet  HWaddr 0a:58:0a:80:00:17  
          inet addr:10.128.0.23  Bcast:10.128.1.255  Mask:255.255.254.0
          inet6 addr: fe80::e04d:64ff:fe54:442/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:8951  Metric:1
          RX packets:4204 errors:0 dropped:0 overruns:0 frame:0
          TX packets:135250 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:3134491 (3.1 MB)  TX bytes:17054774 (17.0 MB)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:6138 errors:0 dropped:0 overruns:0 frame:0
          TX packets:6138 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:479042 (479.0 KB)  TX bytes:479042 (479.0 KB)
```

5. Execute tcpdump command

```
$ sudo tcpdump -vvv -A -i eth0 '((dst port 8080) and (net 10.128.0.23))'
tcpdump: listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
```

6. Open another terminal and cd to the  openshift_istio_ansible project.
- Get your host IP address.
- Get the nodeport of the service. Execute

```
./show_node_port.sh
123456
```

7. Access the url http://your.node.ip.address:123456

```
$ curl http://your.node.ip.address:123456
customer => preference => recommendation v2 from 768fb5c766-pnb9j: 3
```

8. In your tcpdump window, show your audience that the traffic is not encrypted

```
.6...+..GET / HTTP/1.1
host: preference:8080
accept: text/plain, text/plain, application/json, application/json, application/*+json, application/*+json, */*, */*
x-b3-traceid: b9d52af47111bacb
x-b3-parentspanid: ca364e04616e7219
x-b3-spanid: ed29109d03deba60
x-b3-sampled: 1
baggage-user-agent: curl/7.29.0
user-agent: Apache-HttpClient/4.5.3 (Java/1.8.0_151)
accept-encoding: gzip,deflate
x-forwarded-proto: http
x-request-id: fa76226c-3ee3-9fb7-a94f-974b573e415b
x-envoy-decorator-operation: preference.tutorial.svc.cluster.local:8080/*
```

9. Now we enable mutual TLS. Execute

```
[root@18 mutual_tls]# ap 02_enable_mtls.yaml
```

10. Now do another  request

```
$ curl http://your.node.ip.address:123456
customer => preference => recommendation v2 from 768fb5c766-pnb9j: 4
```

11. In your tcpdump window, show your audience the encrypted traffic:

```
...........Y*1g...p.......
.="..=".....;..........gi...H.4..DDN4ELE.R..A..P.u.A.`1.s..m...<...6ksV.>.W1.3Q.Nw.}C..+..|V.R..F.*anl.)j...AM.#6
......=..!C...i....x.z.'..,.0..p!^...m..+...P:8..i:I....Z....$........
..@..x
;..1.X5.a.I......9>.e........$....5tz.w
h......r..>3..{.).e.L...........p.........l..U(.......TS..-...>k.E.K.M.	.......q|....3.E.....w.4j3[...GP+.is|..:s	....]D.\$0k.............u..z...Kw`c..!	.4. *...Q..b.v%mI.....Z.V...m......o..i$..N..2..B.m..*O....K.P	4=.p......:..Pe.&.t_....Y.fe.z.....`>Z|.'P.YJ.`x.`....KkI..l.mF.i.<..@...8...&..F...*..6.....D=.i&4.......ci.0..x^.ke.I.+DP..x..&..8.`.hOJ..%...Q.E....j.@p... DAB}..H...".. s.38...K...9.yk.#....R...Z.1.CT&,;..GJ.T[.W.z..H..f&:...[.iS..........x......b.....=.......U.U..R.'.+.....Z..$0.z+.^..dH....+..T6yB ..L......e....._[.U......X*C..m..sz...GxGiZ`.g.......J......\.&.Y.........$Db.....;....7.......(..a5.L.....4......k.i..3.U..X.."....o..I.g....6w=...@`.5.7..._|..|...1.XH(.*...`..j.]m.....s,./$....I..@.v.HDu;..,>=.'7.)U...KA...rn.y.A..}!.7..!.e)zH.::F,d....xf......7{..o........F...l.9>.Q.i..}*...0.A..J...Nb...h.E}r...c.D..m..,.L,z-)W.b.	.F.3.
```

12.  Now clean up by executing the following 

```
ap 03_disable_mtls.yaml
ap 04_delete_gateway.yaml
ap 05_restore_route.yaml
```
13. Go to your tcpdump window and exit from the rsh.

14. Ensure all istio resources are gone by checking:

```
[root@18 mutual_tls]# bash ../show_istio_resources.sh 
No resources found.
No resources found.
No resources found.
No resources found.
No resources found.
```

### Demo Simple Routing
1. cd to directory openshift_istio_ansible/simple_routing

2. Show the audience that you have pods running:

```
[root@18 mutual_tls]# oc get pods
NAME                                 READY     STATUS    RESTARTS   AGE
customer-5f76f7f8ff-qkfvv            2/2       Running   0          41m
preference-v1-8486bd5ff5-jszp9       2/2       Running   0          41m
recommendation-v1-768fb5c766-pnb9j   2/2       Running   0          40m
```

3. Access the customer route to show it is using version 1 of recommendation:

```
[root@18 simple_routing]# for i in `seq 1 10`; do curl http://customer-tutorial.18.214.127.95.nip.io; done
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 1
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 2
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 3
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 4
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 5
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 6
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 7
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 8
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 9
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 10
```

4. Create recommmendation version v2. Execute

```
ap 01_recommendation.yaml
```

4. Show the audience you now have version 2 running:

```
[root@18 simple_routing]# oc get pods
NAME                                 READY     STATUS    RESTARTS   AGE
customer-5f76f7f8ff-qkfvv            2/2       Running   0          43m
preference-v1-8486bd5ff5-jszp9       2/2       Running   0          43m
recommendation-v1-768fb5c766-pnb9j   2/2       Running   0          43m
recommendation-v2-5f6cb4855b-mkqgr   1/2       Running   0          6s
```
Now would be a good time to explain why you have 1/2 READY and that it will become 2/2 READY.

Access the customer service to show that request is load-balanced between the 2 versions:

```
[root@18 simple_routing]# for i in `seq 1 10`; do curl http://customer-tutorial.18.214.127.95.nip.io/;sleep 0.5 ; done
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 1
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 11
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 2
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 12
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 3
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 13
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 4
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 14
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 5
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 15
```

5. Now scale recommendation v2:

```
ap 02_scale_recommendation.yaml
```
Show the audience you now have  2 version v2 of recommendation.

```
[root@18 simple_routing]# oc get pods
NAME                                 READY     STATUS    RESTARTS   AGE
customer-5f76f7f8ff-qkfvv            2/2       Running   0          1h
preference-v1-8486bd5ff5-jszp9       2/2       Running   0          1h
recommendation-v1-768fb5c766-wpmsq   2/2       Running   0          5m
recommendation-v2-5f6cb4855b-7pknl   1/2       Running   0          4s
recommendation-v2-5f6cb4855b-lzkdk   2/2       Running   0          2m
```

Run again the for loop and show audience that you it called v2 twice because there are 2 pods of v2:

```
[root@18 simple_routing]# for i in `seq 1 10`; do curl http://customer-tutorial.18.214.127.95.nip.io/;sleep 0.5 ; done
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 6
customer => preference => recommendation v2 from 5f6cb4855b-7pknl: 1
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 16
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 7
customer => preference => recommendation v2 from 5f6cb4855b-7pknl: 2
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 17
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 8
customer => preference => recommendation v2 from 5f6cb4855b-7pknl: 3
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 18
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 9
```

6. Scale down recommendation v2

```
ap 03_scale_down_recommendation.yaml
```

7. Now let's have all users go to recommendation v2. This is the blue-green deployment for microservices.

```
ap 04_all_users_recoommendation_v2.yaml
```

Show users that all go to v2:

```
[root@18 simple_routing]# for i in `seq 1 10`; do curl http://customer-tutorial.18.214.127.95.nip.io/;sleep 0.5 ; done
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 10
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 11
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 12
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 13
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 14
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 15
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 16
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 17
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 18
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 19
```

8. Now let's have all users go to recommendation v1.

```
[root@18 simple_routing]# ap  05_all_users_recommendation_v1.yaml
```

```
[root@18 simple_routing]# for i in `seq 1 10`; do curl http://customer-tutorial.18.214.127.95.nip.io/;sleep 0.5 ; done
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 19
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 20
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 21
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 22
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 23
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 24
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 25
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 26
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 27
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 28
```

9. All users even distributed between both versions:

```
ap 06_all_users_recommendation_v1_v2.yaml
```

```
[root@18 simple_routing]# for i in `seq 1 10`; do curl http://customer-tutorial.18.214.127.95.nip.io/;sleep 0.5 ; done
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 20
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 29
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 21
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 30
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 22
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 31
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 23
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 32
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 24
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 33
```

10. Show audience how to do canary deployment in istio. 90% goes to v1 and 10% go to v2.

```
ap 07_canary.yaml

```
```
[root@18 simple_routing]# for i in `seq 1 10`; do curl http://customer-tutorial.18.214.127.95.nip.io/;sleep 0.5 ; done
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 34
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 35
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 36
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 37
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 38
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 25
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 39
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 40
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 41
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 42
```
11. Now we cleanup.

```
ap cleanup.yaml
```

Verify no more stale resources:

```
[root@18 simple_routing]# bash ../show_istio_resources.sh 
No resources found.
No resources found.
No resources found.
No resources found.
No resources found.
```

Both versions should now be equal:
```
[root@18 fault-injection]# for i in `seq 1 10`; do curl http://customer-tutorial.18.214.127.95.nip.io/;sleep 0.5 ; done
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 26
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 43
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 27
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 44
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 28
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 45
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 29
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 46
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 30
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 47
```

### Demo Fault Injection
1. Let's inject 503's to 50% of the requests

```
[root@18 fault-injection]# ap 01_inject_503.yaml
```

```
[root@18 fault-injection]# for i in `seq 1 10`; do curl http://customer-tutorial.18.214.127.95.nip.io/;sleep 0.5 ; done
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 31
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 48
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 32
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 49
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 33
customer => 503 preference => 503 fault filter abort
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 50
customer => 503 preference => 503 fault filter abort
customer => 503 preference => 503 fault filter abort
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 34
```
2. Clean up and Inject delays of 7 seconds to 50% of the requests:

```
ap 02_cleanup.yml
```

Show audience you will inject 7 seconds of fixed delay to 50% of the requests:

```
./show.sh 03_inject_delay.yml

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  creationTimestamp: null
  name: recommendation
  namespace: tutorial
spec:
  hosts:
  - recommendation
  http:
  - fault:
      delay:
        fixedDelay: 7.000s
        percent: 50
    route:
    - destination:
        host: recommendation
        subset: app-recommendation
```

Now execute it:

```
ap 03_inject_delay.yml
```

Run again the loop and let the audience experience slowness:

```
[root@18 fault-injection]# for i in `seq 1 10`; do curl http://customer-tutorial.18.214.127.95.nip.io/;sleep 0.5 ; done
```

3. Clean up and make the service misbehave:

```
ap 04_cleanup.yaml
```

```
ap 05_misbehave.yaml
```

```
[root@18 fault-injection]# for i in `seq 1 10`; do curl http://customer-tutorial.18.214.127.95.nip.io/;sleep 0.5 ; done
customer => 503 preference => 503 recommendation misbehavior from '5f6cb4855b-lzkdk'
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 56
customer => 503 preference => 503 recommendation misbehavior from '5f6cb4855b-lzkdk'
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 57
customer => 503 preference => 503 recommendation misbehavior from '5f6cb4855b-lzkdk'
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 58
customer => 503 preference => 503 recommendation misbehavior from '5f6cb4855b-lzkdk'
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 59
customer => 503 preference => 503 recommendation misbehavior from '5f6cb4855b-lzkdk'
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 60
```

4. Show audience we can retry the call:

```
[root@18 fault-injection]# ./show.sh 06_retry.yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: recommendation
  namespace: tutorial
spec:
  hosts:
  - recommendation
  http:
  - route:
    - destination:
        host: recommendation
    retries:
      attempts: 3
      perTryTimeout: 2s
```

Execute the retry:

```
[root@18 fault-injection]# ap 06_retry.yaml
```

Run the loop to show audience the error is now handled:

```
[root@18 fault-injection]# for i in `seq 1 10`; do curl http://customer-tutorial.18.214.127.95.nip.io/;sleep 0.5 ; done
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 61
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 62
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 63
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 64
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 65
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 66
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 67
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 68
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 69
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 70
```


5. Cleanup and make service behave.

```
[root@18 fault-injection]# ap 07_cleanup.yaml
```

```
[root@18 fault-injection]# ap 08_behave.yaml
```

Run the loop to show we are now back to normal

```
[root@18 fault-injection]# for i in `seq 1 10`; do curl http://customer-tutorial.18.214.127.95.nip.io/;sleep 0.5 ; done
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 1
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 71
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 2
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 72
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 3
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 73
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 4
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 74
customer => preference => recommendation v2 from 5f6cb4855b-lzkdk: 5
customer => preference => recommendation v1 from 768fb5c766-wpmsq: 75
```

Ensure we have not stale  resources:

```
[root@18 fault-injection]# bash ../show_istio_resources.sh 
No resources found.
No resources found.
No resources found.
No resources found.
No resources found.
```

### Demo Circuit Breaker

1. CD to directory openshift_istio_ansible/circuit-breaker
2. Do a clean up first:

```
[root@18 circuit-breaker]# ap 01_cleanup.yaml
```

3. First let's do a load test to show audience the baseline:

```
[root@18 circuit-breaker]# siege -r 2 -c 20 -v http://customer-tutorial.18.214.127.95.nip.io
[alert] Zip encoding disabled; siege requires zlib support to enable it
** SIEGE 4.0.4rc3
** Preparing 20 concurrent users for battle.
The server is now under siege...
HTTP/1.1 200     0.03 secs:      69 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      69 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      69 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.04 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.04 secs:      69 bytes ==> GET  /
HTTP/1.1 200     0.01 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.04 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.02 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.05 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.05 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.05 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.05 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.06 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.02 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.02 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.02 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.02 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.01 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.11 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.11 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.12 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.12 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.12 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.01 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.01 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.01 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.13 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.01 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.01 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.01 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.11 secs:      70 bytes ==> GET  /

Transactions:		          40 hits
Availability:		      100.00 %
Elapsed time:		        0.16 secs
Data transferred:	        0.00 MB
Response time:		        0.04 secs
Transaction rate:	      250.00 trans/sec
Throughput:		        0.02 MB/sec
Concurrency:		       10.88
Successful transactions:          40
Failed transactions:	           0
Longest transaction:	        0.13
Shortest transaction:	        0.01
```

4. Next let's introduce a timeout

```
[root@18 circuit-breaker]# ap 02_introduce_timeout.yaml
```

Repeat the load test:

```
[root@18 circuit-breaker]# siege -r 2 -c 20 -v http://customer-tutorial.18.214.127.95.nip.io
[alert] Zip encoding disabled; siege requires zlib support to enable it
** SIEGE 4.0.4rc3
** Preparing 20 concurrent users for battle.
The server is now under siege...
HTTP/1.1 200     0.02 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.04 secs:      70 bytes ==> GET  /
HTTP/1.1 200     3.04 secs:      69 bytes ==> GET  /
HTTP/1.1 200     3.04 secs:      69 bytes ==> GET  /
HTTP/1.1 200     3.04 secs:      69 bytes ==> GET  /
HTTP/1.1 200     3.05 secs:      71 bytes ==> GET  /
HTTP/1.1 200     3.03 secs:      71 bytes ==> GET  /
HTTP/1.1 200     3.05 secs:      69 bytes ==> GET  /
HTTP/1.1 200     3.02 secs:      69 bytes ==> GET  /
HTTP/1.1 200     3.06 secs:      71 bytes ==> GET  /
HTTP/1.1 200     3.02 secs:      71 bytes ==> GET  /
HTTP/1.1 200     3.06 secs:      71 bytes ==> GET  /
HTTP/1.1 200     3.06 secs:      71 bytes ==> GET  /
HTTP/1.1 200     3.07 secs:      71 bytes ==> GET  /
HTTP/1.1 200     0.01 secs:      71 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      71 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      71 bytes ==> GET  /
HTTP/1.1 200     6.05 secs:      69 bytes ==> GET  /
HTTP/1.1 200     6.05 secs:      71 bytes ==> GET  /
HTTP/1.1 200     6.06 secs:      69 bytes ==> GET  /
HTTP/1.1 200     6.06 secs:      69 bytes ==> GET  /
HTTP/1.1 200     6.06 secs:      71 bytes ==> GET  /
HTTP/1.1 200     0.01 secs:      71 bytes ==> GET  /
HTTP/1.1 200     6.05 secs:      69 bytes ==> GET  /
HTTP/1.1 200     6.08 secs:      70 bytes ==> GET  /
HTTP/1.1 200     3.03 secs:      71 bytes ==> GET  /
HTTP/1.1 200     9.06 secs:      70 bytes ==> GET  /
HTTP/1.1 200     6.01 secs:      70 bytes ==> GET  /
HTTP/1.1 200     6.02 secs:      70 bytes ==> GET  /
HTTP/1.1 200     6.03 secs:      71 bytes ==> GET  /
HTTP/1.1 200     6.03 secs:      71 bytes ==> GET  /
HTTP/1.1 200     3.02 secs:      71 bytes ==> GET  /
HTTP/1.1 200     3.02 secs:      70 bytes ==> GET  /
HTTP/1.1 200     3.00 secs:      71 bytes ==> GET  /
HTTP/1.1 200     6.02 secs:      70 bytes ==> GET  /
HTTP/1.1 200     6.03 secs:      70 bytes ==> GET  /
HTTP/1.1 200     6.02 secs:      70 bytes ==> GET  /
HTTP/1.1 200     3.02 secs:      70 bytes ==> GET  /

Transactions:		          40 hits
Availability:		      100.00 %
Elapsed time:		       12.09 secs
Data transferred:	        0.00 MB
Response time:		        3.64 secs
Transaction rate:	        3.31 trans/sec
Throughput:		        0.00 MB/sec
Concurrency:		       12.03
Successful transactions:          40
Failed transactions:	           0
Longest transaction:	        9.06
Shortest transaction:	        0.01

```

You can compare the Elapsed time and the Longest and Shortest transaction.

5. Now let's add a circuit breaker. Show the audience that this will open the circuit breaker when more than 1 request is being handled by one pod. You can show this via:

```
[root@18 circuit-breaker]# ./show.sh 03_add_circuit_breaker.yaml

apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  creationTimestamp: null
  name: recommendation
  namespace: tutorial
spec:
  host: recommendation
  subsets:
    - name: version-v1
      labels:
        version: v1
    - name: version-v2
      labels:
        version: v2
      trafficPolicy:
        connectionPool:
          http:
            http1MaxPendingRequests: 1
            maxRequestsPerConnection: 1
          tcp:
            maxConnections: 1
        outlierDetection:
          baseEjectionTime: 120.000s
          consecutiveErrors: 1
          interval: 1.000s
          maxEjectionPercent: 100
```

```
[root@18 circuit-breaker]# ap 03_add_circuit_breaker.yaml
```

Do another load test:

```
[root@18 circuit-breaker]# siege -r 2 -c 20 -v http://customer-tutorial.18.214.127.95.nip.io
[alert] Zip encoding disabled; siege requires zlib support to enable it
** SIEGE 4.0.4rc3
** Preparing 20 concurrent users for battle.
The server is now under siege...
HTTP/1.1 200     0.03 secs:      71 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      71 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      71 bytes ==> GET  /
HTTP/1.1 503     0.04 secs:      92 bytes ==> GET  /
HTTP/1.1 503     0.04 secs:      92 bytes ==> GET  /
HTTP/1.1 503     0.04 secs:      92 bytes ==> GET  /
HTTP/1.1 200     0.05 secs:      71 bytes ==> GET  /
HTTP/1.1 503     0.01 secs:      92 bytes ==> GET  /
HTTP/1.1 503     0.05 secs:      92 bytes ==> GET  /
HTTP/1.1 503     0.02 secs:      92 bytes ==> GET  /
HTTP/1.1 200     0.06 secs:      71 bytes ==> GET  /
HTTP/1.1 200     0.06 secs:      71 bytes ==> GET  /
HTTP/1.1 200     0.06 secs:      71 bytes ==> GET  /
HTTP/1.1 503     0.04 secs:      92 bytes ==> GET  /
HTTP/1.1 503     0.04 secs:      92 bytes ==> GET  /
HTTP/1.1 503     0.02 secs:      92 bytes ==> GET  /
HTTP/1.1 503     0.02 secs:      92 bytes ==> GET  /
HTTP/1.1 503     0.05 secs:      92 bytes ==> GET  /
HTTP/1.1 200     0.04 secs:      71 bytes ==> GET  /
HTTP/1.1 503     0.08 secs:      92 bytes ==> GET  /
HTTP/1.1 200     0.03 secs:      71 bytes ==> GET  /
HTTP/1.1 503     0.03 secs:      92 bytes ==> GET  /
HTTP/1.1 200     0.01 secs:      71 bytes ==> GET  /
HTTP/1.1 200     0.11 secs:      71 bytes ==> GET  /
HTTP/1.1 503     0.11 secs:      92 bytes ==> GET  /
HTTP/1.1 503     0.11 secs:      92 bytes ==> GET  /
HTTP/1.1 200     0.01 secs:      71 bytes ==> GET  /
HTTP/1.1 200     0.12 secs:      71 bytes ==> GET  /
HTTP/1.1 200     0.01 secs:      71 bytes ==> GET  /
HTTP/1.1 503     0.12 secs:      92 bytes ==> GET  /
HTTP/1.1 200     0.01 secs:      71 bytes ==> GET  /
HTTP/1.1 503     0.01 secs:      92 bytes ==> GET  /
HTTP/1.1 503     0.10 secs:      92 bytes ==> GET  /
HTTP/1.1 503     0.11 secs:      92 bytes ==> GET  /
HTTP/1.1 200     3.02 secs:      70 bytes ==> GET  /
HTTP/1.1 200     3.03 secs:      70 bytes ==> GET  /
HTTP/1.1 200     0.00 secs:      71 bytes ==> GET  /
HTTP/1.1 200     0.11 secs:      71 bytes ==> GET  /
HTTP/1.1 200     6.03 secs:      70 bytes ==> GET  /
HTTP/1.1 200     3.01 secs:      70 bytes ==> GET  /

Transactions:		          21 hits
Availability:		       52.50 %
Elapsed time:		        9.04 secs
Data transferred:	        0.00 MB
Response time:		        0.80 secs
Transaction rate:	        2.32 trans/sec
Throughput:		        0.00 MB/sec
Concurrency:		        1.87
Successful transactions:          21
Failed transactions:	          19
Longest transaction:	        6.03
Shortest transaction:	        0.01
```

Compare the Elapsed time and Longest/Shortest transaction

# That's it!
