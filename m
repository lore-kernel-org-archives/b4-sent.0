From: Laika Price <laikabcprice@gmail.com>
Date: Sat, 13 Jun 2026 16:12:18 +0100
Subject: [PATCH net v2 2/2] selftests: pmtu: fix incorrect PMTU exception
 generation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260613-master-v2-2-061b70fd45dd@gmail.com>
References: <20260613-master-v2-0-061b70fd45dd@gmail.com>
In-Reply-To: <20260613-master-v2-0-061b70fd45dd@gmail.com>
To: David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Laika Price <laikabcprice@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781363541; l=1559;
 i=laikabcprice@gmail.com; s=20260613; h=from:subject:message-id;
 bh=EB7JD3oI/Fpm2bkrfDJdH/qbu3251WqBWWjNhI2DYYM=;
 b=f4F5woWRmK8h6Q1dIwcyXaCXS6wPgWhwk96cSQywjZ8iRa54P16GPL9ImVtdSAot/J81rhPrd
 xHM7r6GJtNlDCWq45emc4ZR2JDx7elaIM3e9y+SeBzfn4x/6GHL1P4+
X-Developer-Key: i=laikabcprice@gmail.com; a=ed25519;
 pk=mFSMw2odvyxt1H4QHAdwZVuwHduNzUMDKbWFOcwhDCg=
X-Endpoint-Received: by B4 Relay for laikabcprice@gmail.com/20260613 with auth_id=819
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pmtu_ipv4_br_vxlan4_exception generates PMTU exceptions by pinging an IP
on the other side of a tunnel. This was incorrect as it would return upon
the first ICMP Fragmentation Needed due to the -w flag being used in
conjunction with || return 1.

This patch updates pmtu_ipv4_br_vxlan4_exception to be in line with how
PMTU exceptions are generated in other tests such as in test_pmtu_ipvX

    run_cmd ${ns_a} ${ping} -q -M want -i 0.1 -w 1 -s 1800 ${dst1}
    run_cmd ${ns_a} ${ping} -q -M want -i 0.1 -w 1 -s 1800 ${dst2}

Signed-off-by: Laika Price <laikabcprice@gmail.com>
---
 tools/testing/selftests/net/pmtu.sh | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/tools/testing/selftests/net/pmtu.sh b/tools/testing/selftests/net/pmtu.sh
index a3323c21f..9498d9f53 100755
--- a/tools/testing/selftests/net/pmtu.sh
+++ b/tools/testing/selftests/net/pmtu.sh
@@ -1456,8 +1456,8 @@ test_pmtu_ipvX_over_bridged_vxlanY_or_geneveY_exception() {
 	mtu "${ns_a}" ${type}_a $((${ll_mtu} + 1000))
 	mtu "${ns_b}" ${type}_b $((${ll_mtu} + 1000))
 
-	run_cmd ${ns_c} ${ping} -q -M want -i 0.1 -c 10 -s $((${ll_mtu} + 500)) ${dst} || return 1
-	run_cmd ${ns_a} ${ping} -q -M want -i 0.1 -w 1  -s $((${ll_mtu} + 500)) ${dst} || return 1
+	run_cmd ${ns_c} ${ping} -q -M want -i 0.1 -w 1 -s $((${ll_mtu} + 500)) ${dst}
+	run_cmd ${ns_a} ${ping} -q -M want -i 0.1 -w 1 -s $((${ll_mtu} + 500)) ${dst}
 
 	# Check that exceptions were created
 	pmtu="$(route_get_dst_pmtu_from_exception "${ns_c}" ${dst})"

-- 
2.54.0

