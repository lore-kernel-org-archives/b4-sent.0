From: Bernd Schubert <bernd@bsbernd.com>
Date: Wed, 30 Sep 2026 15:44:36 +0200
Subject: [PATCH 4/4] mount/fuse_service: share the service socket helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-mount-service-use-mount-fsmount-v1-4-d585598896ee@bsbernd.com>
References: <20260930-mount-service-use-mount-fsmount-v1-0-d585598896ee@bsbernd.com>
In-Reply-To: <20260930-mount-service-use-mount-fsmount-v1-0-d585598896ee@bsbernd.com>
To: "Darrick J. Wong" <djwong@kernel.org>
Cc: neal@gompa.dev, fuse-devel@lists.linux.dev, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=13124; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=3VmP4v0xJgVk/cNYnIWidFMEmx+d6QwJgfmYICYgnz4=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL2Cvn+CKni+GRx5KTD+2dmPBtmB3ufWrxbO2WVWMXKK
 Tu2HzqU11HKwiDGwSArpsjSJbHHdso/Plm1r+uvw8xhZQIZwsDFKQATUbNhZDj+veDNnbNf60oz
 GH3Kkm7xHrh75M4Swe2dC9+xaiofe6bAyHC/sddzevf7WdMqJKfN+eKZpy976/4Lc6Pt96wsrky
 o9mcEAA==
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

lib/fuse_service.c and util/mount_service.c each had their own sendmsg()
and recvmsg() for the same packets, repeating MSG_EOR|MSG_NOSIGNAL and
MSG_TRUNC, plus their own SO_SNDBUF check. Every change to how a packet
travels had to be made twice.

fuse_service_send_packet(), fuse_service_recv_packet() and
fuse_service_sendbuf_too_small() move to include/fuse_service_priv.h,
which both files already include for the packet layout. The error
messages differ per file and stay in the callers.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 include/fuse_service_priv.h | 59 +++++++++++++++++++++++++++++++++++++
 lib/fuse_service.c          | 72 ++++++++++-----------------------------------
 util/mount_service.c        | 59 ++++++-------------------------------
 3 files changed, 83 insertions(+), 107 deletions(-)

diff --git a/include/fuse_service_priv.h b/include/fuse_service_priv.h
index 988f7c9251c8..951694faaaba 100644
--- a/include/fuse_service_priv.h
+++ b/include/fuse_service_priv.h
@@ -9,6 +9,9 @@
 #ifndef FUSE_SERVICE_PRIV_H_
 #define FUSE_SERVICE_PRIV_H_
 
+#include <sys/socket.h>
+#include <limits.h>
+
 /* All numeric fields are network order (big-endian) when going across the socket */
 
 struct fuse_service_memfd_arg {
@@ -48,6 +51,36 @@ struct fuse_service_packet {
 	uint32_t magic;			/* FUSE_SERVICE_*_{CMD,REPLY} */
 };
 
+static inline ssize_t fuse_service_send_packet(int sockfd, void *ptr,
+					       size_t len)
+{
+	struct iovec iov = {
+		.iov_base = ptr,
+		.iov_len = len,
+	};
+	struct msghdr msg = {
+		.msg_iov = &iov,
+		.msg_iovlen = 1,
+	};
+
+	return sendmsg(sockfd, &msg, MSG_EOR | MSG_NOSIGNAL);
+}
+
+static inline ssize_t fuse_service_recv_packet(int sockfd, void *ptr,
+					       size_t len)
+{
+	struct iovec iov = {
+		.iov_base = ptr,
+		.iov_len = len,
+	};
+	struct msghdr msg = {
+		.msg_iov = &iov,
+		.msg_iovlen = 1,
+	};
+
+	return recvmsg(sockfd, &msg, MSG_TRUNC);
+}
+
 #define FUSE_SERVICE_PROTO	(1)
 #define FUSE_SERVICE_MIN_PROTO	(1)
 #define FUSE_SERVICE_MAX_PROTO	(1)
@@ -117,6 +150,32 @@ static inline size_t sizeof_fuse_service_open_command(size_t pathlen)
 	return sizeof(struct fuse_service_open_command) + pathlen + 1;
 }
 
+/*
+ * A send buffer that cannot hold the largest open command makes the sendmsg
+ * fail later on; report the size so the caller can say so in its own words.
+ * A buffer we cannot query is not an error - most likely we won't be sending
+ * huge open commands, and if we do, the sendmsg will fail there too.
+ *
+ * @sendbuf_sizep set to the offending size when the buffer is too small
+ * @return true if the send buffer is too small
+ */
+static inline bool fuse_service_sendbuf_too_small(int sockfd,
+						  int *sendbuf_sizep)
+{
+	int sendbuf_size = -1;
+	socklen_t optlen = sizeof(sendbuf_size);
+
+	if (getsockopt(sockfd, SOL_SOCKET, SO_SNDBUF, &sendbuf_size, &optlen) ||
+	    sendbuf_size < 0)
+		return false;
+
+	if ((size_t)sendbuf_size >= sizeof_fuse_service_open_command(PATH_MAX))
+		return false;
+
+	*sendbuf_sizep = sendbuf_size;
+	return true;
+}
+
 struct fuse_service_string_command {
 	struct fuse_service_packet p;
 	char value[];
diff --git a/lib/fuse_service.c b/lib/fuse_service.c
index 0a05b3fbc1f2..1f3fc1be0888 100644
--- a/lib/fuse_service.c
+++ b/lib/fuse_service.c
@@ -135,36 +135,6 @@ static int __recv_fd(const struct fuse_service *sf,
 	return 0;
 }
 
-static ssize_t __send_packet(const struct fuse_service *sf, void *ptr,
-			     size_t len)
-{
-	struct iovec iov = {
-		.iov_base = ptr,
-		.iov_len = len,
-	};
-	struct msghdr msg = {
-		.msg_iov = &iov,
-		.msg_iovlen = 1,
-	};
-
-	return sendmsg(sf->sockfd, &msg, MSG_EOR | MSG_NOSIGNAL);
-}
-
-static ssize_t __recv_packet(const struct fuse_service *sf, void *ptr,
-			     size_t len)
-{
-	struct iovec iov = {
-		.iov_base = ptr,
-		.iov_len = len,
-	};
-	struct msghdr msg = {
-		.msg_iov = &iov,
-		.msg_iovlen = 1,
-	};
-
-	return recvmsg(sf->sockfd, &msg, MSG_TRUNC);
-}
-
 int fuse_service_receive_file(const struct fuse_service *sf, const char *path,
 			      int *fdp)
 {
@@ -266,7 +236,7 @@ static int fuse_service_request_path(const struct fuse_service *sf,
 	cmd->request_flags = htonl(rqflags);
 	memcpy(cmd->path, path, pathlen + 1);
 
-	size = __send_packet(sf, cmd, cmdsz);
+	size = fuse_service_send_packet(sf->sockfd, cmd, cmdsz);
 	if (size < 0) {
 		int error = errno;
 
@@ -313,7 +283,7 @@ int fuse_service_send_goodbye(struct fuse_service *sf, int exitcode)
 	if (sf->sockfd < 0)
 		return 0;
 
-	size = __send_packet(sf, &c, sizeof(c));
+	size = fuse_service_send_packet(sf->sockfd, &c, sizeof(c));
 	if (size < 0) {
 		int error = errno;
 
@@ -367,25 +337,13 @@ static int count_listen_fds(void)
 
 static int check_sendbuf_size(int sockfd)
 {
-	const size_t min_size = sizeof_fuse_service_open_command(PATH_MAX);
-	int sendbuf_size = -1;
-	socklen_t optlen = sizeof(sendbuf_size);
-	int ret;
+	int sendbuf_size;
 
-	/*
-	 * If we can't query the maximum send buffer length, just keep going.
-	 * Most likely we won't be sending huge open commands, and if we do,
-	 * the sendmsg will fail there too.
-	 */
-	ret = getsockopt(sockfd, SOL_SOCKET, SO_SNDBUF, &sendbuf_size, &optlen);
-	if (ret || sendbuf_size < 0)
-		return 0;
-
-	if (sendbuf_size >= min_size)
+	if (!fuse_service_sendbuf_too_small(sockfd, &sendbuf_size))
 		return 0;
 
 	fuse_log(FUSE_LOG_ERR, "max socket send buffer is %d, need at least %zu.\n",
-		 sendbuf_size, min_size);
+		 sendbuf_size, sizeof_fuse_service_open_command(PATH_MAX));
 	return -ENOBUFS;
 }
 
@@ -456,7 +414,7 @@ static int negotiate_hello(struct fuse_service *sf)
 	uint32_t flags;
 	ssize_t size;
 
-	size = __recv_packet(sf, &hello, sizeof(hello));
+	size = fuse_service_recv_packet(sf->sockfd, &hello, sizeof(hello));
 	if (size < 0) {
 		int error = errno;
 
@@ -511,7 +469,7 @@ static int negotiate_hello(struct fuse_service *sf)
 	if (flags & FUSE_SERVICE_FLAG_FUSEBLK)
 		sf->can_fuseblk = true;
 
-	size = __send_packet(sf, &reply, sizeof(reply));
+	size = fuse_service_send_packet(sf->sockfd, &reply, sizeof(reply));
 	if (size < 0) {
 		int error = errno;
 
@@ -821,7 +779,7 @@ static int send_fsopen(const struct fuse_service *sf, const char *fstype,
 	if (!strncmp(fstype, "fuseblk", 7))
 		c.fsopen_flags |= htonl(FUSE_SERVICE_FSOPEN_FUSEBLK);
 
-	size = __send_packet(sf, &c, sizeof(c));
+	size = fuse_service_send_packet(sf->sockfd, &c, sizeof(c));
 	if (size < 0) {
 		int error = errno;
 
@@ -830,7 +788,7 @@ static int send_fsopen(const struct fuse_service *sf, const char *fstype,
 		return -error;
 	}
 
-	size = __recv_packet(sf, &reply, sizeof(reply));
+	size = fuse_service_recv_packet(sf->sockfd, &reply, sizeof(reply));
 	if (size < 0) {
 		int error = errno;
 
@@ -873,7 +831,7 @@ static int send_string(const struct fuse_service *sf, uint32_t command,
 	cmd->p.magic = htonl(command);
 	memcpy(cmd->value, value, valuelen + 1);
 
-	size = __send_packet(sf, cmd, cmdsz);
+	size = fuse_service_send_packet(sf->sockfd, cmd, cmdsz);
 	if (size < 0) {
 		err = -errno;
 		fuse_log(FUSE_LOG_ERR, "fuse: send service string: %s\n",
@@ -881,7 +839,7 @@ static int send_string(const struct fuse_service *sf, uint32_t command,
 		goto out;
 	}
 
-	size = __recv_packet(sf, &reply, sizeof(reply));
+	size = fuse_service_recv_packet(sf->sockfd, &reply, sizeof(reply));
 	if (size < 0) {
 		err = -errno;
 		fuse_log(FUSE_LOG_ERR, "fuse: service string reply: %s\n",
@@ -929,7 +887,7 @@ static int send_mountpoint(const struct fuse_service *sf, mode_t expected_fmt,
 	cmd->expected_fmt = htons(expected_fmt);
 	memcpy(cmd->value, value, valuelen + 1);
 
-	size = __send_packet(sf, cmd, cmdsz);
+	size = fuse_service_send_packet(sf->sockfd, cmd, cmdsz);
 	if (size < 0) {
 		err = -errno;
 		fuse_log(FUSE_LOG_ERR, "fuse: send service mountpoint: %s\n",
@@ -937,7 +895,7 @@ static int send_mountpoint(const struct fuse_service *sf, mode_t expected_fmt,
 		goto out;
 	}
 
-	size = __recv_packet(sf, &reply, sizeof(reply));
+	size = fuse_service_recv_packet(sf->sockfd, &reply, sizeof(reply));
 	if (size < 0) {
 		err = -errno;
 		fuse_log(FUSE_LOG_ERR, "fuse: service mountpoint reply: %s\n",
@@ -975,7 +933,7 @@ static int send_mount(const struct fuse_service *sf, unsigned int ms_flags,
 	};
 	ssize_t size;
 
-	size = __send_packet(sf, &c, sizeof(c));
+	size = fuse_service_send_packet(sf->sockfd, &c, sizeof(c));
 	if (size < 0) {
 		int error = errno;
 
@@ -984,7 +942,7 @@ static int send_mount(const struct fuse_service *sf, unsigned int ms_flags,
 		return -error;
 	}
 
-	size = __recv_packet(sf, &reply, sizeof(reply));
+	size = fuse_service_recv_packet(sf->sockfd, &reply, sizeof(reply));
 	if (size < 0) {
 		int error = errno;
 
diff --git a/util/mount_service.c b/util/mount_service.c
index dcdc26df1db4..47cc2d43d2a0 100644
--- a/util/mount_service.c
+++ b/util/mount_service.c
@@ -139,21 +139,6 @@ static ssize_t __send_fd(const struct mount_service *mo,
 	return sendmsg(mo->sockfd, &msg, MSG_EOR | MSG_NOSIGNAL);
 }
 
-static ssize_t __send_packet(const struct mount_service *mo, void *ptr,
-			     size_t len)
-{
-	struct iovec iov = {
-		.iov_base = ptr,
-		.iov_len = len,
-	};
-	struct msghdr msg = {
-		.msg_iov = &iov,
-		.msg_iovlen = 1,
-	};
-
-	return sendmsg(mo->sockfd, &msg, MSG_EOR | MSG_NOSIGNAL);
-}
-
 static ssize_t __recv_packet_size(const struct mount_service *mo)
 {
 	struct iovec iov = { };
@@ -164,21 +149,6 @@ static ssize_t __recv_packet_size(const struct mount_service *mo)
 	return recvmsg(mo->sockfd, &msg, MSG_PEEK | MSG_TRUNC);
 }
 
-static ssize_t __recv_packet(const struct mount_service *mo, void *ptr,
-			     size_t len)
-{
-	struct iovec iov = {
-		.iov_base = ptr,
-		.iov_len = len,
-	};
-	struct msghdr msg = {
-		.msg_iov = &iov,
-		.msg_iovlen = 1,
-	};
-
-	return recvmsg(mo->sockfd, &msg, MSG_TRUNC);
-}
-
 /*
  * Filter out the subtype of the filesystem (e.g. fuse.Y[.Z] -> Y[.Z]).  The
  * fuse server determines if it's appropriate to set the "blockdev" mount
@@ -271,25 +241,14 @@ static int try_drop_passrights(const struct mount_service *mo, int sockfd)
 
 static int check_sendbuf_size(const struct mount_service *mo, int sockfd)
 {
-	const size_t min_size = sizeof_fuse_service_open_command(PATH_MAX);
-	int sendbuf_size = -1;
-	socklen_t optlen = sizeof(sendbuf_size);
-	int ret;
+	int sendbuf_size;
 
-	/*
-	 * If we can't query the maximum send buffer length, just keep going.
-	 * Most likely we won't be sending huge open commands, and if we do,
-	 * the sendmsg will fail there too.
-	 */
-	ret = getsockopt(sockfd, SOL_SOCKET, SO_SNDBUF, &sendbuf_size, &optlen);
-	if (ret || sendbuf_size < 0)
-		return 0;
-
-	if (sendbuf_size >= min_size)
+	if (!fuse_service_sendbuf_too_small(sockfd, &sendbuf_size))
 		return 0;
 
 	fprintf(stderr, "%s: max socket send buffer is %d, need at least %zu.\n",
-		mo->msgtag, sendbuf_size, min_size);
+		mo->msgtag, sendbuf_size,
+		sizeof_fuse_service_open_command(PATH_MAX));
 	return MOUNT_SERVICE_FALLBACK_NEEDED;
 }
 
@@ -369,14 +328,14 @@ static int mount_service_send_hello(const struct mount_service *mo)
 	else if (user_allow_other)
 		hello.flags |= htonl(FUSE_SERVICE_FLAG_ALLOW_OTHER);
 
-	size = __send_packet(mo, &hello, sizeof(hello));
+	size = fuse_service_send_packet(mo->sockfd, &hello, sizeof(hello));
 	if (size < 0) {
 		fprintf(stderr, "%s: send hello: %s\n",
 			mo->msgtag, strerror(errno));
 		return -1;
 	}
 
-	size = __recv_packet(mo, &reply, sizeof(reply));
+	size = fuse_service_recv_packet(mo->sockfd, &reply, sizeof(reply));
 	if (size < 0) {
 		fprintf(stderr, "%s: hello reply: %s\n",
 			mo->msgtag, strerror(errno));
@@ -581,7 +540,7 @@ static int mount_service_send_file_error(const struct mount_service *mo,
 	req->error = htonl(error);
 	memcpy(req->path, path, path_len + 1);
 
-	written = __send_packet(mo, req, req_sz);
+	written = fuse_service_send_packet(mo->sockfd, req, req_sz);
 	if (written < 0) {
 		fprintf(stderr, "%s: send file error: %s\n",
 			mo->msgtag, strerror(errno));
@@ -671,7 +630,7 @@ static int mount_service_receive_command(const struct mount_service *mo,
 		return -1;
 	}
 
-	size = __recv_packet(mo, command, alleged_size);
+	size = fuse_service_recv_packet(mo->sockfd, command, alleged_size);
 	if (size < 0) {
 		fprintf(stderr, "%s: receive service command: %s\n",
 			mo->msgtag, strerror(errno));
@@ -698,7 +657,7 @@ static int mount_service_send_reply(const struct mount_service *mo, int error)
 	};
 	ssize_t size;
 
-	size = __send_packet(mo, &reply, sizeof(reply));
+	size = fuse_service_send_packet(mo->sockfd, &reply, sizeof(reply));
 	if (size < 0) {
 		fprintf(stderr, "%s: send service reply: %s\n",
 			mo->msgtag, strerror(errno));

-- 
2.53.0

