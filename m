From: Jhonata Poma-Hansen <jhonata.poma@gmail.com>
Date: Tue, 27 Oct 2026 15:04:02 +0100
Subject: [PATCH net v2 2/2] selftests: net: netlink-dumps: start a dump
 with a notification queued
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-netlink-dump-livelock-v2-2-c4bb05352a33@gmail.com>
References: <20261027-netlink-dump-livelock-v2-0-c4bb05352a33@gmail.com>
In-Reply-To: <20261027-netlink-dump-livelock-v2-0-c4bb05352a33@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Kuniyuki Iwashima <kuniyu@google.com>, 
 Marek Szyprowski <m.szyprowski@samsung.com>, 
 Jhonata Poma-Hansen <jhonata.poma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4013;
 i=jhonata.poma@gmail.com; h=from:subject:message-id;
 bh=QvCDY24BNqHaFSZD0SluMGJ84blsufGLlWuNu8gQX+A=;
 b=owGbwMvMwCX21S6Y7aK9oS7jabUkhqwH64Oktjz70LHhuN/z+bsPVT9ic2zlunBItb7ZKW/ez
 CcJue+nd5SyMIhxMciKKbL4nH3cw634ccf/hzsuw8xhZQIZwsDFKQATUc1m+Ct5hXee5qeannOO
 L63VN/EGRmTfnHil1E6o8+3xsmknPd8yMiy/sixsXejrmtCzkqv1LBs8FNk3Cvz/w2k/u2Wl2SV
 tbm4A
X-Developer-Key: i=jhonata.poma@gmail.com; a=openpgp;
 fpr=4CCDE38C0B21F1B8FFE1B8D3F53E5306D13F312D
X-Endpoint-Received: by B4 Relay for jhonata.poma@gmail.com/default with auth_id=1288
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a test which starts a link dump on a socket with SO_RCVBUF 2048
while a link notification is still queued, after a large read made the
kernel attempt large dump skbs. It reads like libnl does, peeking
before each read, and expects the dump to complete with a zero status
and at least one link. The notifications come from bringing lo up and
down, so the test runs in its own netns and is skipped without the
privileges to create one.

The test fails without the previous patch.

Signed-off-by: Jhonata Poma-Hansen <jhonata.poma@gmail.com>
---
 tools/testing/selftests/net/netlink-dumps.c | 102 ++++++++++++++++++++++++++++
 1 file changed, 102 insertions(+)

diff --git a/tools/testing/selftests/net/netlink-dumps.c b/tools/testing/selftests/net/netlink-dumps.c
index 51129c564..4a94a2516 100644
--- a/tools/testing/selftests/net/netlink-dumps.c
+++ b/tools/testing/selftests/net/netlink-dumps.c
@@ -2,9 +2,12 @@
 
 #define _GNU_SOURCE
 
+#include <errno.h>
 #include <fcntl.h>
+#include <sched.h>
 #include <stdio.h>
 #include <string.h>
+#include <sys/ioctl.h>
 #include <sys/socket.h>
 #include <sys/stat.h>
 #include <sys/syscall.h>
@@ -260,4 +263,103 @@ TEST(close_with_ref)
 	usleep(100 * 1000);
 }
 
+static int lo_set_up(int sock, bool up)
+{
+	struct ifreq ifr = {};
+
+	strcpy(ifr.ifr_name, "lo");
+	if (ioctl(sock, SIOCGIFFLAGS, &ifr))
+		return -1;
+	if (up)
+		ifr.ifr_flags |= IFF_UP;
+	else
+		ifr.ifr_flags &= ~IFF_UP;
+	return ioctl(sock, SIOCSIFFLAGS, &ifr);
+}
+
+static const struct {
+	struct nlmsghdr nlhdr;
+	struct ifinfomsg ifm;
+} dump_links = {
+	.nlhdr = {
+		.nlmsg_len	= sizeof(dump_links),
+		.nlmsg_type	= RTM_GETLINK,
+		.nlmsg_flags	= NLM_F_REQUEST | NLM_F_ACK | NLM_F_DUMP,
+		.nlmsg_seq	= 1,
+	},
+	.ifm = {
+		.ifi_family	= AF_UNSPEC,
+	},
+};
+
+// A dump started while a notification is still queued must make progress
+// for a reader which peeks before reading, like libnl does
+TEST(dump_with_queued_ntf)
+{
+	struct sockaddr_nl addr = {
+		.nl_family	= AF_NETLINK,
+		.nl_groups	= RTMGRP_LINK,
+	};
+	int netlink_sock, inet_sock, i, ret, links = 0;
+	int rcvbuf = 2048;
+	bool done = false;
+	char buf[32768];
+	ssize_t n;
+
+	ret = unshare(CLONE_NEWNET);
+	if (ret && errno == EPERM)
+		SKIP(return, "Needs CAP_SYS_ADMIN for a netns");
+	ASSERT_EQ(ret, 0);
+
+	inet_sock = socket(AF_INET, SOCK_DGRAM, 0);
+	ASSERT_GE(inet_sock, 0);
+	netlink_sock = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
+	ASSERT_GE(netlink_sock, 0);
+	ASSERT_EQ(setsockopt(netlink_sock, SOL_SOCKET, SO_RCVBUF,
+			     &rcvbuf, sizeof(rcvbuf)), 0);
+	ASSERT_EQ(bind(netlink_sock, (struct sockaddr *)&addr,
+		       sizeof(addr)), 0);
+
+	// A large read makes the kernel attempt large dump skbs
+	ASSERT_EQ(lo_set_up(inet_sock, true), 0);
+	n = recv(netlink_sock, buf, sizeof(buf), 0);
+	ASSERT_GE(n, (ssize_t)sizeof(struct nlmsghdr));
+
+	// Leave one notification queued, then start the dump
+	ASSERT_EQ(lo_set_up(inet_sock, false), 0);
+	n = send(netlink_sock, &dump_links, sizeof(dump_links), 0);
+	ASSERT_EQ(n, sizeof(dump_links));
+
+	for (i = 0; i < 100 && !done; i++) {
+		struct nlmsghdr *nlh;
+
+		n = recv(netlink_sock, buf, sizeof(buf),
+			 MSG_PEEK | MSG_TRUNC | MSG_DONTWAIT);
+		if (n < 0)
+			continue;
+		n = recv(netlink_sock, buf, sizeof(buf), MSG_DONTWAIT);
+		if (n < 0)
+			continue;
+
+		for (nlh = (struct nlmsghdr *)buf; NLMSG_OK(nlh, n);
+		     nlh = NLMSG_NEXT(nlh, n)) {
+			if (nlh->nlmsg_seq != dump_links.nlhdr.nlmsg_seq)
+				continue;
+			if (nlh->nlmsg_type == NLMSG_ERROR)
+				EXPECT_EQ(*(int *)NLMSG_DATA(nlh), 0);
+			if (nlh->nlmsg_type == RTM_NEWLINK)
+				links++;
+			if (nlh->nlmsg_type == NLMSG_DONE) {
+				EXPECT_EQ(*(int *)NLMSG_DATA(nlh), 0);
+				done = true;
+			}
+		}
+	}
+	EXPECT_TRUE(done);
+	EXPECT_GE(links, 1);
+
+	close(netlink_sock);
+	close(inet_sock);
+}
+
 TEST_HARNESS_MAIN

-- 
2.54.0

