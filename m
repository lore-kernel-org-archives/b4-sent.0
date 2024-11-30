From: Levi Zim <rsworktech@outlook.com>
Date: Sat, 30 Nov 2024 21:38:23 +0800
Subject: [PATCH net 2/2] tcp_bpf: fix copied value in tcp_bpf_sendmsg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241130-tcp-bpf-sendmsg-v1-2-bae583d014f3@outlook.com>
References: <20241130-tcp-bpf-sendmsg-v1-0-bae583d014f3@outlook.com>
In-Reply-To: <20241130-tcp-bpf-sendmsg-v1-0-bae583d014f3@outlook.com>
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, David Ahern <dsahern@kernel.org>
Cc: netdev@vger.kernel.org, bpf@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Levi Zim <rsworktech@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2613;
 i=rsworktech@outlook.com; h=from:subject:message-id;
 bh=BSkGG9GTRoR+hvU0RGsIgrZN4wSOYMDvwCLwhO4xA0I=;
 b=owEBbQKS/ZANAwAIAW87mNQvxsnYAcsmYgBnSxV/R4dBaQRVcQRIIaNhbEPgxR11GIvnSrfk0
 FNrgI8Ds9qJAjMEAAEIAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCZ0sVfwAKCRBvO5jUL8bJ
 2JhIEADFnoc0KrtgtrkTiauoo1Nu6q/SztNB5pqKgENVv6F8U11ZtAThNKgJZ0bAqOedmgz5Sa5
 rNVW2ooN6hS4zKVq5SGypoGoMqx9k+dEX8B7NP7eQpcU+HOhyXx0eTKZs8P8Yre2UL9N4ZJdRMF
 AiCTaPnh+Cs3nnuJTK5yMsPsc9c4miizFTzs34FidtHRZ/mRayXqMkVqBnI5aVx6WzoThrtI/mY
 wGbDC9Qa2jzzAovMCbooG9lxTch9mzRM/p0sbBOAve5eMRnkagDDEqWRPP+sbfhkd+U06REtM8S
 95K8uBtqDgQUXSvVdwD2vv2CgDqvkAtHoSehPN47Rcq9JnATvSLxkQqqi1kWWRKvdgHz6Dmm2cy
 Iy83wsC5iydLapfsWp/vUn60NAHBYBQtaBNpOMl/mZIiWXZCLaq2+UMT+Ybf9tTx3bn/9wdgSUC
 yIiMvdl57DAobJRLzr+tcFQ6AiKTHOAZ1pmuzkAY9sv3VCDdyZWTlvdljJdiGoM1lf1pNX5VAdq
 cQcc2hQ1Kmzz1xoUQGv2eRlZ7yiT0YgDVPWs900RGh5N34V6cml7qhDy36RIpv0EIOu/OIBmstL
 rJ887YIecSfwhK311xHvFjyrCiDcj+4e9SAfYZhV0+ZwirotZ+QM7aiSbZAaoc32pC1pp4ct0HD
 3VbRGGq8Qa/z4rw==
X-Developer-Key: i=rsworktech@outlook.com; a=openpgp;
 fpr=17AADD6726DDC58B8EE5881757670CCFA42CCF0A
X-Endpoint-Received: by B4 Relay for rsworktech@outlook.com/default with auth_id=219
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bpf kselftest sockhash::test_txmsg_cork_hangs in test_sockmap.c triggers a
kernel NULL pointer dereference:

BUG: kernel NULL pointer dereference, address: 0000000000000008
 ? __die_body+0x6e/0xb0
 ? __die+0x8b/0xa0
 ? page_fault_oops+0x358/0x3c0
 ? local_clock+0x19/0x30
 ? lock_release+0x11b/0x440
 ? kernelmode_fixup_or_oops+0x54/0x60
 ? __bad_area_nosemaphore+0x4f/0x210
 ? mmap_read_unlock+0x13/0x30
 ? bad_area_nosemaphore+0x16/0x20
 ? do_user_addr_fault+0x6fd/0x740
 ? prb_read_valid+0x1d/0x30
 ? exc_page_fault+0x55/0xd0
 ? asm_exc_page_fault+0x2b/0x30
 ? splice_to_socket+0x52e/0x630
 ? shmem_file_splice_read+0x2b1/0x310
 direct_splice_actor+0x47/0x70
 splice_direct_to_actor+0x133/0x300
 ? do_splice_direct+0x90/0x90
 do_splice_direct+0x64/0x90
 ? __ia32_sys_tee+0x30/0x30
 do_sendfile+0x214/0x300
 __se_sys_sendfile64+0x8e/0xb0
 __x64_sys_sendfile64+0x25/0x30
 x64_sys_call+0xb82/0x2840
 do_syscall_64+0x75/0x110
 entry_SYSCALL_64_after_hwframe+0x4b/0x53

This is caused by tcp_bpf_sendmsg() returning a larger value(12289) than
size (8192), which causes the while loop in splice_to_socket() to release
an uninitialized pipe buf.

The underlying cause is that this code assumes sk_msg_memcopy_from_iter()
will copy all bytes upon success but it actually might only copy part of
it.

This commit changes it to use the real copied bytes.

Signed-off-by: Levi Zim <rsworktech@outlook.com>
---
 net/ipv4/tcp_bpf.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/net/ipv4/tcp_bpf.c b/net/ipv4/tcp_bpf.c
index 370993c03d31363c0f82a003d9e5b0ca3bbed721..8e46c4d618cbbff0d120fe4cd917624e5d5cae15 100644
--- a/net/ipv4/tcp_bpf.c
+++ b/net/ipv4/tcp_bpf.c
@@ -496,7 +496,7 @@ static int tcp_bpf_send_verdict(struct sock *sk, struct sk_psock *psock,
 static int tcp_bpf_sendmsg(struct sock *sk, struct msghdr *msg, size_t size)
 {
 	struct sk_msg tmp, *msg_tx = NULL;
-	int copied = 0, err = 0;
+	int copied = 0, err = 0, ret = 0;
 	struct sk_psock *psock;
 	long timeo;
 	int flags;
@@ -539,14 +539,14 @@ static int tcp_bpf_sendmsg(struct sock *sk, struct msghdr *msg, size_t size)
 			copy = msg_tx->sg.size - osize;
 		}
 
-		err = sk_msg_memcopy_from_iter(sk, &msg->msg_iter, msg_tx,
+		ret = sk_msg_memcopy_from_iter(sk, &msg->msg_iter, msg_tx,
 					       copy);
-		if (err < 0) {
+		if (ret < 0) {
 			sk_msg_trim(sk, msg_tx, osize);
 			goto out_err;
 		}
 
-		copied += copy;
+		copied += ret;
 		if (psock->cork_bytes) {
 			if (size > psock->cork_bytes)
 				psock->cork_bytes = 0;

-- 
2.47.1

