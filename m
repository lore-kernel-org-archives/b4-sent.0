From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 23 Nov 2026 15:30:44 +0100
Subject: [PATCH net 2/2] selftests: fib_tests: test IPv6 source address of
 a VRF
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-for-upstream-ipv6-vrf-saddr-scope-v1-v1-2-f667ab150ade@free.fr>
References: <20261123-for-upstream-ipv6-vrf-saddr-scope-v1-v1-0-f667ab150ade@free.fr>
In-Reply-To: <20261123-for-upstream-ipv6-vrf-saddr-scope-v1-v1-0-f667ab150ade@free.fr>
To: David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Willem de Bruijn <willemb@google.com>, Simon Horman <horms@kernel.org>, 
 Nicolas Dichtel <nicolas.dichtel@6wind.com>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795444251; l=2772;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=0STye+l3ERrEJAJtqNrYiXotiM7u53bz2yrMtrVkjkw=;
 b=qiwPhBIlFTL8P4Yn34sxtIoj06Mm3Ue5AhtHH4xD9ba9H8BugQcMgpAc8QVmOoq6hpBtK//VX
 +mjKP9j5lUoDgwNA+YSJGRgPe1HzSz+3LwFEWhEyaGjg/4eurXAuvy1
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check the IPv6 source address of a route of a VRF through a device
that only has an IPv6 link-local address:
  - the address of another device of the VRF
  - then the one of the VRF device once it has one
  - then the one of the output device

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 tools/testing/selftests/net/fib_tests.sh | 47 +++++++++++++++++++++++++++++++-
 1 file changed, 46 insertions(+), 1 deletion(-)

diff --git a/tools/testing/selftests/net/fib_tests.sh b/tools/testing/selftests/net/fib_tests.sh
index d7ac3c727f704..e211ea5a945ef 100755
--- a/tools/testing/selftests/net/fib_tests.sh
+++ b/tools/testing/selftests/net/fib_tests.sh
@@ -14,7 +14,7 @@ TESTS="unregister down carrier nexthop suppress ipv6_notify ipv4_notify \
        ipv4_mpath_list ipv6_mpath_list ipv4_mpath_balance ipv6_mpath_balance \
        ipv4_mpath_balance_preferred ipv4_mpath_oif ipv4_mpath_oif_nh \
        ipv4_mpath_oif_vrf ipv6_mpath_oif ipv6_mpath_oif_nh ipv6_mpath_oif_vrf \
-       fib6_ra_to_static fib6_temp_addr_renewal"
+       ipv6_saddr_vrf fib6_ra_to_static fib6_temp_addr_renewal"
 
 VERBOSE=0
 PAUSE_ON_FAIL=no
@@ -3228,6 +3228,50 @@ ipv6_mpath_oif_vrf_test()
 	cleanup
 }
 
+ipv6_saddr_vrf_check()
+{
+	local saddr="$1"
+	local desc="$2"
+	local route_get="$IP -6 route get 2001:db8:10::1 vrf vrf-123"
+
+	run_cmd "$route_get | grep -q 'src $saddr '"
+	log_test $? 0 "$desc"
+}
+
+ipv6_saddr_vrf_test()
+{
+	echo
+	echo "IPv6 source address selection with VRF test"
+
+	setup
+
+	if ! $IP link add name vrf-123 up type vrf table 123 &> /dev/null; then
+		echo "SKIP: Could not add a VRF device."
+		cleanup
+		return
+	fi
+
+	set -e
+	$NS_EXEC sysctl -qw net.ipv6.conf.all.keep_addr_on_down=1
+	$IP link set dev dummy0 master vrf-123
+	$IP link add dummy1 up master vrf-123 type dummy
+	$IP -6 route add 2001:db8:10::/64 vrf vrf-123 dev dummy1
+	set +e
+
+	ipv6_saddr_vrf_check "2001:db8:1::1" \
+		"Output device with a link-local address only"
+
+	$IP address add 2001:db8:100::1/128 dev vrf-123 nodad
+	ipv6_saddr_vrf_check "2001:db8:100::1" \
+		"Address of the VRF device before those of other devices"
+
+	$IP address add 2001:db8:2::1/64 dev dummy1 nodad
+	ipv6_saddr_vrf_check "2001:db8:2::1" \
+		"Address of the output device first"
+
+	cleanup
+}
+
 ################################################################################
 # usage
 
@@ -3320,6 +3364,7 @@ do
 	ipv6_mpath_oif)			ipv6_mpath_oif_test;;
 	ipv6_mpath_oif_nh)		ipv6_mpath_oif_nh_test;;
 	ipv6_mpath_oif_vrf)		ipv6_mpath_oif_vrf_test;;
+	ipv6_saddr_vrf)			ipv6_saddr_vrf_test;;
 	fib6_ra_to_static)		fib6_ra_to_static;;
 	fib6_temp_addr_renewal)		fib6_temp_addr_renewal;;
 

-- 
2.43.0

