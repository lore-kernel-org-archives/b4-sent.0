From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Wed, 02 Apr 2025 01:59:31 +0100
Subject: [PATCH net-next] net/selftests: Add loopback link local route for
 self-connect
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250402-tcp-ao-selfconnect-flake-v1-1-8388d629ef3d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPKL7GcC/zWMywrCQAwAf6XkbDCuL/BXxEM2Zm2wpmV3kULpv
 7sKHodhZoGi2bTApVsg69uKjd5gt+lAevaHot0bQ6BwpAMFrDIhj1h0SDK6q1RMAz8VlZij0F7
 ofIKWT1mTzb/1FVwrus4Vbs1ELooxs0v/Xf/d9sXmsK4fxrqPW5QAAAA=
X-Change-ID: 20250402-tcp-ao-selfconnect-flake-e0aabc03c076
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743555610; l=2603;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=VxuHQuF+lHn7Z66dGwiCR30NCU5Nd0bRf7ml37EyIQ0=;
 b=3aqwhOYRQXABmt30DhIo05TJTESR3xflbbuTR3dBAmI3yMdgAoZyxUVPrqaM+Ncc8k/aXIzyA
 mxoO5rvkEHQC0Jz5Odvs0oX666np6SxSESKORHPedn8ROHccfn/nftx
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

self-connect-ipv6 got slightly flaky on netdev:
> # timeout set to 120
> # selftests: net/tcp_ao: self-connect_ipv6
> # 1..5
> # # 708[lib/setup.c:250] rand seed 1742872572
> # TAP version 13
> # # 708[lib/proc.c:213]    Snmp6            Ip6OutNoRoutes: 0 => 1
> # not ok 1 # error 708[self-connect.c:70] failed to connect()
> # ok 2 No unexpected trace events during the test run
> # # Planned tests != run tests (5 != 2)
> # # Totals: pass:1 fail:0 xfail:0 xpass:0 skip:0 error:1
> ok 1 selftests: net/tcp_ao: self-connect_ipv6

I can not reproduce it on my machines, but judging by "Ip6OutNoRoutes"
there is no route to the local_addr (::1).

Looking at the kernel code, I see that kernel does add link-local
address automatically in init_loopback(), but that is called from
ipv6 notifier block. So, in turn the userspace that brought up
the loopback interface may see rtnetlink ACK earlier than
addrconf_notify() does it's job (at least, on a slow VM such as netdev).
Probably, for ipv4 it's the same, judging by inetdev_event().

The fix is quite simple: set the link-local route straight after
bringing the loopback interface. That will make it synchronous.

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
Sorry to send this during the merge window, it's a test stability fix.
It seems that netdev build bot has hit the issue a couple of times, but
seems not hitting it constantly at this moment:

https://netdev.bots.linux.dev/flakes.html?br-cnt=150&tn-needle=tcp-ao

I'm marking it net-next, so that build bot carries it until the merge
closes. If it's not fine, I can re-send it after the merge window.
---
 tools/testing/selftests/net/tcp_ao/self-connect.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/tools/testing/selftests/net/tcp_ao/self-connect.c b/tools/testing/selftests/net/tcp_ao/self-connect.c
index 73b2f2276f3f5410aaa74bede7f366f81761bd6e..2c73bea698a677f9aedd7bec28f6e7fee7845d2e 100644
--- a/tools/testing/selftests/net/tcp_ao/self-connect.c
+++ b/tools/testing/selftests/net/tcp_ao/self-connect.c
@@ -16,6 +16,9 @@ static void __setup_lo_intf(const char *lo_intf,
 
 	if (link_set_up(lo_intf))
 		test_error("Failed to bring %s up", lo_intf);
+
+	if (ip_route_add(lo_intf, TEST_FAMILY, local_addr, local_addr))
+		test_error("Failed to add a local route %s", lo_intf);
 }
 
 static void setup_lo_intf(const char *lo_intf)

---
base-commit: 1a9239bb4253f9076b5b4b2a1a4e8d7defd77a95
change-id: 20250402-tcp-ao-selfconnect-flake-e0aabc03c076

Best regards,
-- 
Dmitry Safonov <0x7f454c46@gmail.com>

