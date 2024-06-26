From: Luigi Leonardi <luigi.leonardi@outlook.com>
Date: Wed, 26 Jun 2024 14:08:37 +0200
Subject: [PATCH net-next v3 3/3] test/vsock: add ioctl unsent bytes test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240626-ioctl_next-v3-3-63be5bf19a40@outlook.com>
References: <20240626-ioctl_next-v3-0-63be5bf19a40@outlook.com>
In-Reply-To: <20240626-ioctl_next-v3-0-63be5bf19a40@outlook.com>
To: Stefano Garzarella <sgarzare@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Stefan Hajnoczi <stefanha@redhat.com>, 
 "Michael S. Tsirkin" <mst@redhat.com>, Jason Wang <jasowang@redhat.com>, 
 =?utf-8?q?Eugenio_P=C3=A9rez?= <eperezma@redhat.com>, 
 Xuan Zhuo <xuanzhuo@linux.alibaba.com>
Cc: virtualization@lists.linux.dev, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kvm@vger.kernel.org, 
 Luigi Leonardi <luigi.leonardi@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719403717; l=5287;
 i=luigi.leonardi@outlook.com; s=20240626; h=from:subject:message-id;
 bh=FDpHJLS9kfgD7unmHav2FhVRFU78BRFdz0KEgUfk8vw=;
 b=TuJ/P23fgGZ+s3Q91ayKbKfOaprwu5UZ0qqn6gFtrq8ov1iB0WPwIR0+sGOZdCQ+FB1H5Mftb
 tzM1kHGr4WXB/CDMlKi/OlyMAXR2t2qoIjkAYK5dkLJ1lS8tIQeAwPb
X-Developer-Key: i=luigi.leonardi@outlook.com; a=ed25519;
 pk=RYXD8JyCxGnx/izNc/6b3g3pgpohJMAI0LJ7ynxXzi8=
X-Endpoint-Received: by B4 Relay for luigi.leonardi@outlook.com/20240626 with auth_id=177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce two tests, one for SOCK_STREAM and one for SOCK_SEQPACKET, which checks
after a packet is delivered, that the number of unsent bytes is zero,
using ioctl SIOCOUTQ.

Signed-off-by: Luigi Leonardi <luigi.leonardi@outlook.com>
---
 tools/testing/vsock/util.c       |  6 +--
 tools/testing/vsock/util.h       |  3 ++
 tools/testing/vsock/vsock_test.c | 85 ++++++++++++++++++++++++++++++++++++++++
 3 files changed, 91 insertions(+), 3 deletions(-)

diff --git a/tools/testing/vsock/util.c b/tools/testing/vsock/util.c
index 554b290fefdc..a3d448a075e3 100644
--- a/tools/testing/vsock/util.c
+++ b/tools/testing/vsock/util.c
@@ -139,7 +139,7 @@ int vsock_bind_connect(unsigned int cid, unsigned int port, unsigned int bind_po
 }
 
 /* Connect to <cid, port> and return the file descriptor. */
-static int vsock_connect(unsigned int cid, unsigned int port, int type)
+int vsock_connect(unsigned int cid, unsigned int port, int type)
 {
 	union {
 		struct sockaddr sa;
@@ -226,8 +226,8 @@ static int vsock_listen(unsigned int cid, unsigned int port, int type)
 /* Listen on <cid, port> and return the first incoming connection.  The remote
  * address is stored to clientaddrp.  clientaddrp may be NULL.
  */
-static int vsock_accept(unsigned int cid, unsigned int port,
-			struct sockaddr_vm *clientaddrp, int type)
+int vsock_accept(unsigned int cid, unsigned int port,
+		 struct sockaddr_vm *clientaddrp, int type)
 {
 	union {
 		struct sockaddr sa;
diff --git a/tools/testing/vsock/util.h b/tools/testing/vsock/util.h
index e95e62485959..fff22d4a14c0 100644
--- a/tools/testing/vsock/util.h
+++ b/tools/testing/vsock/util.h
@@ -39,6 +39,9 @@ struct test_case {
 void init_signals(void);
 unsigned int parse_cid(const char *str);
 unsigned int parse_port(const char *str);
+int vsock_connect(unsigned int cid, unsigned int port, int type);
+int vsock_accept(unsigned int cid, unsigned int port,
+		 struct sockaddr_vm *clientaddrp, int type);
 int vsock_stream_connect(unsigned int cid, unsigned int port);
 int vsock_bind_connect(unsigned int cid, unsigned int port,
 		       unsigned int bind_port, int type);
diff --git a/tools/testing/vsock/vsock_test.c b/tools/testing/vsock/vsock_test.c
index f851f8961247..76bd17b4b291 100644
--- a/tools/testing/vsock/vsock_test.c
+++ b/tools/testing/vsock/vsock_test.c
@@ -20,6 +20,8 @@
 #include <sys/mman.h>
 #include <poll.h>
 #include <signal.h>
+#include <sys/ioctl.h>
+#include <linux/sockios.h>
 
 #include "vsock_test_zerocopy.h"
 #include "timeout.h"
@@ -1238,6 +1240,79 @@ static void test_double_bind_connect_client(const struct test_opts *opts)
 	}
 }
 
+#define MSG_BUF_IOCTL_LEN 64
+static void test_unsent_bytes_server(const struct test_opts *opts, int type)
+{
+	unsigned char buf[MSG_BUF_IOCTL_LEN];
+	int client_fd;
+
+	client_fd = vsock_accept(VMADDR_CID_ANY, 1234, NULL, type);
+	if (client_fd < 0) {
+		perror("accept");
+		exit(EXIT_FAILURE);
+	}
+
+	recv_buf(client_fd, buf, sizeof(buf), 0, sizeof(buf));
+	control_writeln("RECEIVED");
+
+	close(client_fd);
+}
+
+static void test_unsent_bytes_client(const struct test_opts *opts, int type)
+{
+	unsigned char buf[MSG_BUF_IOCTL_LEN];
+	int ret, fd, sock_bytes_unsent;
+
+	fd = vsock_connect(opts->peer_cid, 1234, type);
+	if (fd < 0) {
+		perror("connect");
+		exit(EXIT_FAILURE);
+	}
+
+	for (int i = 0; i < sizeof(buf); i++)
+		buf[i] = rand() & 0xFF;
+
+	send_buf(fd, buf, sizeof(buf), 0, sizeof(buf));
+	control_expectln("RECEIVED");
+
+	ret = ioctl(fd, SIOCOUTQ, &sock_bytes_unsent);
+	if (ret < 0) {
+		if (errno == EOPNOTSUPP) {
+			fprintf(stderr, "Test skipped\n");
+		} else {
+			perror("ioctl");
+			exit(EXIT_FAILURE);
+		}
+	} else if (ret == 0 && sock_bytes_unsent != 0) {
+		fprintf(stderr,
+			"Unexpected 'SIOCOUTQ' value, expected 0, got %i\n",
+			sock_bytes_unsent);
+		exit(EXIT_FAILURE);
+	}
+
+	close(fd);
+}
+
+static void test_stream_unsent_bytes_client(const struct test_opts *opts)
+{
+	test_unsent_bytes_client(opts, SOCK_STREAM);
+}
+
+static void test_stream_unsent_bytes_server(const struct test_opts *opts)
+{
+	test_unsent_bytes_server(opts, SOCK_STREAM);
+}
+
+static void test_seqpacket_unsent_bytes_client(const struct test_opts *opts)
+{
+	test_unsent_bytes_client(opts, SOCK_SEQPACKET);
+}
+
+static void test_seqpacket_unsent_bytes_server(const struct test_opts *opts)
+{
+	test_unsent_bytes_server(opts, SOCK_SEQPACKET);
+}
+
 #define RCVLOWAT_CREDIT_UPD_BUF_SIZE	(1024 * 128)
 /* This define is the same as in 'include/linux/virtio_vsock.h':
  * it is used to decide when to send credit update message during
@@ -1523,6 +1598,16 @@ static struct test_case test_cases[] = {
 		.run_client = test_stream_rcvlowat_def_cred_upd_client,
 		.run_server = test_stream_cred_upd_on_low_rx_bytes,
 	},
+	{
+		.name = "SOCK_STREAM ioctl(SIOCOUTQ) 0 unsent bytes",
+		.run_client = test_stream_unsent_bytes_client,
+		.run_server = test_stream_unsent_bytes_server,
+	},
+	{
+		.name = "SOCK_SEQPACKET ioctl(SIOCOUTQ) 0 unsent bytes",
+		.run_client = test_seqpacket_unsent_bytes_client,
+		.run_server = test_seqpacket_unsent_bytes_server,
+	},
 	{},
 };
 

-- 
2.45.2

