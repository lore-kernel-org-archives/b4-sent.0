From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Sat, 13 Apr 2024 17:48:48 +0300
Subject: [PATCH iproute2-next] man: use clsact qdisc for port mirroring
 examples on matchall and mirred
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240413-man-use-clsact-qdisc-for-matchall-and-mirred-v1-1-5c9f61677863@arinc9.com>
X-B4-Tracking: v=1; b=H4sIAE+bGmYC/x2NQQrDMAwEvxJ0rsB2c0j7ldKDsJVW4Nip5JRAy
 N9rehyW2TnAWIUN7sMByl8xqaWDvwwQ31RejJI6Q3BhdKO/4kIFN2OM2Sg2/CSxiHPVPrRu5Ix
 UEi6iygl9ZE/JT9PNEfTLVXmW/Z97gKxat8YBC+8Nnuf5A/pTU7aNAAAA
To: David Ahern <dsahern@gmail.com>
Cc: mithat.guner@xeront.com, erkin.bozoglu@xeront.com, 
 netdev@vger.kernel.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713019729; l=3826;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=vrR61UQ6opmiSgRd+8Wr6u70ATLGyaGEmpbKTeNQ45I=;
 b=ycbw3z0aWIaCTa+GsYqrfZf5AcHbaMLY8sfjJQxoNs3VUh7bcnSH0svyAhG1KaY9jkFeJlgj4
 QTJtOQRwCtyDv6MRYDs8z/HAK0wrcKwBB9SJmoug4pglC9jJGBcfptX
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The clsact qdisc supports ingress and egress. Instead of using two qdiscs
to do ingress and egress port mirroring, clsact can be used. Therefore, use
clsact for the port mirroring examples on the tc-matchall.8 and tc-mirred.8
documents.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
I've got another incentive that pushed me to make this change.

https://lore.kernel.org/netdev/fce3c587-eca3-402f-a31f-5473fd2cd6eb@arinc9.com/

Arınç
---
 man/man8/tc-matchall.8 | 20 ++++++++++----------
 man/man8/tc-mirred.8   | 12 ++++++------
 2 files changed, 16 insertions(+), 16 deletions(-)

diff --git a/man/man8/tc-matchall.8 b/man/man8/tc-matchall.8
index d0224066..538cf745 100644
--- a/man/man8/tc-matchall.8
+++ b/man/man8/tc-matchall.8
@@ -37,39 +37,39 @@ To create ingress mirroring from port eth1 to port eth2:
 .RS
 .EX
 
-tc qdisc  add dev eth1 handle ffff: ingress
-tc filter add dev eth1 parent ffff:           \\
+tc qdisc  add dev eth1 handle ffff: clsact
+tc filter add dev eth1 ingress                \\
         matchall skip_sw                      \\
         action mirred egress mirror           \\
         dev eth2
 .EE
 .RE
 
-The first command creates an ingress qdisc with handle
+The first command creates a clsact qdisc with handle
 .BR ffff:
 on device
 .BR eth1
 where the second command attaches a matchall filters on it that mirrors the
-packets to device eth2.
+packets to device eth2 for ingress.
 
 To create egress mirroring from port eth1 to port eth2:
 .RS
 .EX
 
-tc qdisc add dev eth1 handle 1: root prio
-tc filter add dev eth1 parent 1:               \\
+tc qdisc add dev eth1 handle ffff: clsact
+tc filter add dev eth1 egress                  \\
         matchall skip_sw                       \\
         action mirred egress mirror            \\
         dev eth2
 .EE
 .RE
 
-The first command creates an egress qdisc with handle
-.BR 1:
-that replaces the root qdisc on device
+The first command creates a clsact qdisc with handle
+.BR ffff:
+on device
 .BR eth1
 where the second command attaches a matchall filters on it that mirrors the
-packets to device eth2.
+packets to device eth2 for egress.
 
 To sample one of every 100 packets flowing into interface eth0 to psample group
 12:
diff --git a/man/man8/tc-mirred.8 b/man/man8/tc-mirred.8
index ea408467..01801be4 100644
--- a/man/man8/tc-mirred.8
+++ b/man/man8/tc-mirred.8
@@ -75,8 +75,8 @@ debugging purposes:
 
 .RS
 .EX
-# tc qdisc add dev eth0 handle ffff: ingress
-# tc filter add dev eth0 parent ffff: u32 \\
+# tc qdisc add dev eth0 handle ffff: clsact
+# tc filter add dev eth0 ingress u32 \\
 	match u32 0 0 \\
 	action police rate 1mbit burst 100k conform-exceed pipe \\
 	action mirred egress redirect dev lo
@@ -90,8 +90,8 @@ with e.g. tcpdump:
 .EX
 # ip link add dummy0 type dummy
 # ip link set dummy0 up
-# tc qdisc add dev eth0 handle ffff: ingress
-# tc filter add dev eth0 parent ffff: protocol ip \\
+# tc qdisc add dev eth0 handle ffff: clsact
+# tc filter add dev eth0 ingress protocol ip \\
 	u32 match ip protocol 1 0xff \\
 	action mirred egress mirror dev dummy0
 .EE
@@ -107,8 +107,8 @@ interface, it is possible to send ingress traffic through an instance of
 # modprobe ifb
 # ip link set ifb0 up
 # tc qdisc add dev ifb0 root sfq
-# tc qdisc add dev eth0 handle ffff: ingress
-# tc filter add dev eth0 parent ffff: u32 \\
+# tc qdisc add dev eth0 handle ffff: clsact
+# tc filter add dev eth0 ingress u32 \\
 	match u32 0 0 \\
 	action mirred egress redirect dev ifb0
 .EE

---
base-commit: 7a6d30c95da98fbb375e7f1520fad34c1e959441
change-id: 20240413-man-use-clsact-qdisc-for-matchall-and-mirred-1ce1ad18890a

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

