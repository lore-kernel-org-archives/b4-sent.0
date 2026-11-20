From: Kalash Nainwal <kalash@nexthop.ai>
Date: Fri, 20 Nov 2026 15:47:05 -0700
Subject: [PATCH net-next 1/2] tcp: add net.ipv4.tcp_l3mdev_exempt_ports
 sysctl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-tcp-l3mdev-exempt-ports-v1-1-ccc2a3a6cd09@nexthop.ai>
References: <20261120-tcp-l3mdev-exempt-ports-v1-0-ccc2a3a6cd09@nexthop.ai>
In-Reply-To: <20261120-tcp-l3mdev-exempt-ports-v1-0-ccc2a3a6cd09@nexthop.ai>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, David Ahern <dsahern@kernel.org>, 
 Ido Schimmel <idosch@nvidia.com>, Neal Cardwell <ncardwell@google.com>, 
 Kuniyuki Iwashima <kuniyu@google.com>
Cc: netdev@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Kalash Nainwal <kalash@nexthop.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=6449; i=kalash@nexthop.ai;
 h=from:subject:message-id; bh=fge2VqvDTzCL4vkfcc2/Isy48/QGoz89laMvzHs6z7U=;
 b=owEB7QES/pANAwAKAdTKslu1X9B2AcsmYgBrAM3p/bhC7/61T3tuKXc7PadU0EisdV+PNqnlY
 kmxGTBYd6WJAbMEAAEKAB0WIQSWKdfHnHcAucb08LDUyrJbtV/QdgUCawDN6QAKCRDUyrJbtV/Q
 dpwbC/9wbi57/yCvWFVnu8hG63SWQ1CwqTln+ghvRO+cSd/yOouLFDWnSEomZ11Mm9gsw/lHvew
 x9s38cXuG0muUYXR9Oje/+wCeDF2w0Ob/wRQLxDYFf/rw7XCXliML5BrU8t3vytjE3jMZFnvV5T
 FybYpcMg/zmOoEVkVRTvEaPkDA76a5KHTBAafwHa2pnDXvgN6jKK6xK25ech6FfUTQf64xFXoyx
 IcoiubWlIMKD678zAxBKQo/l7G9F8fUBjnUM83jeH5wYYsBSW9BtW0nF7KtuC44KzcEWjbbbOns
 rKvDr1QqH+zoFatTyyJ2J7+gwwqjAoDn5lAjS4Zg2AwE/L5hVhpNmYawiuAFfqd8IqepObdWbxm
 YZ4LAF08vZ1MGBelcNXZMc/j85QlWuw8TXT+Fij4Ln4bVY+RRd0ZCo2Lkh+0DLxmahyUrpL/+gb
 r8pcxri5luOBXHK9ojQT8GD6tjJvM4uIzQI6W2oVrV0ZRzk5Bc/ru55KlXy7OHvXkmsok=
X-Developer-Key: i=kalash@nexthop.ai; a=openpgp;
 fpr=9629D7C79C7700B9C6F4F0B0D4CAB25BB55FD076
X-Endpoint-Received: by B4 Relay for kalash@nexthop.ai/default with auth_id=1588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With tcp_l3mdev_accept=1, an unbound listener also matches connections
that arrive in a VRF. If a VRF-bound listener exists on the same port
and both use SO_REUSEPORT, the lookup returns whichever is first in the
listen bucket, not the VRF-bound one. Since AF_INET and AF_INET6
reuseport sockets are inserted at opposite ends of the bucket, the same
setup can pick the VRF-bound listener for IPv4 and the unbound one for
IPv6.

This breaks, for example, a BGP daemon with a TCP-MD5 key only on its
VRF-bound listener: IPv6 peers in the VRF reach the unbound listener
and the session comes up without MD5.

Add net.ipv4.tcp_l3mdev_exempt_ports, a per-netns port list in the
same format as ip_local_reserved_ports. For a listed port, an unbound
socket does not match connections that arrive in a VRF, so only a
VRF-bound listener can take them. Other ports and default-VRF traffic
are not affected. The default is empty.

Signed-off-by: Kalash Nainwal <kalash@nexthop.ai>
---
 Documentation/networking/ip-sysctl.rst | 19 +++++++++++++++++++
 include/net/ip.h                       | 14 ++++++++++++++
 include/net/netns/ipv4.h               |  1 +
 net/ipv4/inet_hashtables.c             |  5 +++++
 net/ipv4/sysctl_net_ipv4.c             | 14 ++++++++++++++
 net/ipv6/inet6_hashtables.c            |  4 ++++
 6 files changed, 57 insertions(+)

diff --git a/Documentation/networking/ip-sysctl.rst b/Documentation/networking/ip-sysctl.rst
index 3cc80d9b024..1de0ee5c0d5 100644
--- a/Documentation/networking/ip-sysctl.rst
+++ b/Documentation/networking/ip-sysctl.rst
@@ -619,6 +619,25 @@ tcp_l3mdev_accept - BOOLEAN
 
 	Default: 0 (disabled)
 
+tcp_l3mdev_exempt_ports - list of comma separated ranges
+	TCP ports for which tcp_l3mdev_accept is ignored. When
+	tcp_l3mdev_accept is enabled, a listen socket that is not bound to
+	an L3 master device also matches connections that arrive in an L3
+	domain (e.g., a VRF). For a port in this list, such a socket does
+	not match these connections; only a listen socket bound to the L3
+	master device does. Connections that do not arrive in an L3 domain
+	are not affected. This applies to both IPv4 and IPv6.
+
+	This is useful when the same port has both an unbound listener and
+	a listener bound to a VRF, and VRF connections must reach the
+	VRF-bound one (for example, when only it has TCP-MD5 or TCP-AO
+	keys configured).
+
+	The format is the same as ip_local_reserved_ports, e.g.
+	"179,5000-5010". Writing to the file replaces the current list.
+
+	Default: empty
+
 tcp_low_latency - BOOLEAN
 	This is a legacy option, it has no effect anymore.
 
diff --git a/include/net/ip.h b/include/net/ip.h
index 5035b313a26..c6581080a9a 100644
--- a/include/net/ip.h
+++ b/include/net/ip.h
@@ -396,6 +396,20 @@ static inline bool inet_port_requires_bind_service(struct net *net, unsigned sho
 }
 #endif
 
+/* Ports listed in net.ipv4.tcp_l3mdev_exempt_ports behave as if
+ * tcp_l3mdev_accept were 0: an unbound listener does not match traffic
+ * received on an L3 master device slave. Applies to IPv4 and IPv6.
+ */
+static inline bool tcp_port_l3mdev_exempt(const struct net *net,
+					  unsigned short port)
+{
+#ifdef CONFIG_SYSCTL
+	if (net->ipv4.sysctl_tcp_l3mdev_exempt_ports)
+		return test_bit(port, net->ipv4.sysctl_tcp_l3mdev_exempt_ports);
+#endif
+	return false;
+}
+
 __be32 inet_current_timestamp(void);
 
 /* From inetpeer.c */
diff --git a/include/net/netns/ipv4.h b/include/net/netns/ipv4.h
index 3efbc7f4b4f..899d90f34a7 100644
--- a/include/net/netns/ipv4.h
+++ b/include/net/netns/ipv4.h
@@ -271,6 +271,7 @@ struct netns_ipv4 {
 
 #ifdef CONFIG_SYSCTL
 	unsigned long *sysctl_local_reserved_ports;
+	unsigned long *sysctl_tcp_l3mdev_exempt_ports;
 	int sysctl_ip_prot_sock;
 #endif
 
diff --git a/net/ipv4/inet_hashtables.c b/net/ipv4/inet_hashtables.c
index 860145d810e..063f6dd00a6 100644
--- a/net/ipv4/inet_hashtables.c
+++ b/net/ipv4/inet_hashtables.c
@@ -362,6 +362,11 @@ static inline int compute_score(struct sock *sk, const struct net *net,
 
 		if (!inet_sk_bound_dev_eq(net, sk->sk_bound_dev_if, dif, sdif))
 			return -1;
+
+		if (!sk->sk_bound_dev_if && sdif &&
+		    tcp_port_l3mdev_exempt(net, hnum))
+			return -1;
+
 		score =  sk->sk_bound_dev_if ? 2 : 1;
 
 		if (sk->sk_family == PF_INET)
diff --git a/net/ipv4/sysctl_net_ipv4.c b/net/ipv4/sysctl_net_ipv4.c
index 9df93ad219d..83d0030512a 100644
--- a/net/ipv4/sysctl_net_ipv4.c
+++ b/net/ipv4/sysctl_net_ipv4.c
@@ -840,6 +840,13 @@ static const struct ctl_table ipv4_net_table[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_do_large_bitmap,
 	},
+	{
+		.procname	= "tcp_l3mdev_exempt_ports",
+		.data		= &init_net.ipv4.sysctl_tcp_l3mdev_exempt_ports,
+		.maxlen		= 65536,
+		.mode		= 0644,
+		.proc_handler	= proc_do_large_bitmap,
+	},
 	{
 		.procname	= "ip_no_pmtu_disc",
 		.data		= &init_net.ipv4.sysctl_ip_no_pmtu_disc,
@@ -1708,10 +1715,16 @@ static __net_init int ipv4_sysctl_init_net(struct net *net)
 	if (!net->ipv4.sysctl_local_reserved_ports)
 		goto err_ports;
 
+	net->ipv4.sysctl_tcp_l3mdev_exempt_ports = kzalloc(65536 / 8, GFP_KERNEL);
+	if (!net->ipv4.sysctl_tcp_l3mdev_exempt_ports)
+		goto err_l3mdev_ports;
+
 	proc_fib_multipath_hash_set_seed(net, 0);
 
 	return 0;
 
+err_l3mdev_ports:
+	kfree(net->ipv4.sysctl_local_reserved_ports);
 err_ports:
 	unregister_net_sysctl_table(net->ipv4.ipv4_hdr);
 err_reg:
@@ -1729,6 +1742,7 @@ static __net_exit void ipv4_sysctl_exit_net(struct net *net)
 	unregister_net_sysctl_table(net->ipv4.ipv4_hdr);
 	kfree(table);
 	kfree(net->ipv4.sysctl_local_reserved_ports);
+	kfree(net->ipv4.sysctl_tcp_l3mdev_exempt_ports);
 }
 
 static __net_initdata struct pernet_operations ipv4_sysctl_ops = {
diff --git a/net/ipv6/inet6_hashtables.c b/net/ipv6/inet6_hashtables.c
index 1eea584d80d..43c52b56e8b 100644
--- a/net/ipv6/inet6_hashtables.c
+++ b/net/ipv6/inet6_hashtables.c
@@ -141,6 +141,10 @@ static inline int compute_score(struct sock *sk, const struct net *net,
 		if (!inet_sk_bound_dev_eq(net, sk->sk_bound_dev_if, dif, sdif))
 			return -1;
 
+		if (!sk->sk_bound_dev_if && sdif &&
+		    tcp_port_l3mdev_exempt(net, hnum))
+			return -1;
+
 		score =  sk->sk_bound_dev_if ? 2 : 1;
 		if (READ_ONCE(sk->sk_incoming_cpu) == raw_smp_processor_id())
 			score++;

-- 
2.43.0

