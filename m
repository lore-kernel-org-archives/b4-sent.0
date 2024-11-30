From: Levi Zim <rsworktech@outlook.com>
Subject: [PATCH net 0/2] Fix NPE discovered by running bpf kselftest
Date: Sat, 30 Nov 2024 21:38:21 +0800
Message-Id: <20241130-tcp-bpf-sendmsg-v1-0-bae583d014f3@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE0VS2cC/x3MQQqAIBBA0avErBvQjMiuEi1Kx5pFJk5EEN09a
 fkW/z8glJkEhuqBTBcLH7FA1xW4bY4rIftiaFTTam0Uni7hkgIKRb/LiiEYZ33fUmcNlCplCnz
 /xxEinTC97wd7UFMuZgAAAA==
X-Change-ID: 20241130-tcp-bpf-sendmsg-ff3c9d84e693
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, David Ahern <dsahern@kernel.org>
Cc: netdev@vger.kernel.org, bpf@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Levi Zim <rsworktech@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1994;
 i=rsworktech@outlook.com; h=from:subject:message-id;
 bh=AtoMv+qZEg3Jrjb92TD+QP+vPH9tNZ1fEkpRkBwkvCs=;
 b=owEBbQKS/ZANAwAIAW87mNQvxsnYAcsmYgBnSxV3VGLEL49AHZ7R/d7EbVg6R8VkrJZM9QKxj
 wCbxoE/uROJAjMEAAEIAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCZ0sVdwAKCRBvO5jUL8bJ
 2HlIEACiRItsYjOk5RJI2/JZUvDi3jlt5j1sj93UCDJRXYAm7dQQpxq38P+uHO3Iyxuz3kgIYfi
 uZmFtrsoU8/kikiFo+JFV7iMebGXZWugkcZFrZ2TpCWXvpKHd7bU/vwo9KhaeC0gQ2e0wsLI8Ee
 Y3DRi7EZyxX/mKIWzLxogiHDpT6esl6AslnH+sbdkIgeK9dpBtB1Ni+ligxBduKwgQDAKqM0MqX
 T1iQoTEAucGQXrAum66ejeeJ81quXXUKl1S/U+rJ0V1Yz2O3m6KZxy8Igz5nxcjbbe5hOHG3xm1
 JCgRW//D/ixRf4fy75vATRQp9tdQsSD/qp4AYBysk5LeBkvz88im03z2W7INhtzMwoONTwfG9ia
 rFQRjDvjfnXuTQ6v1P/3DGiXxPSK/VxAeScG5YTuUA62DcC1lZ38ToiL2wEdWfeSQmCd4lIBk8T
 aBZnwb3dlzy8eXrx/u6CNGIi8N9MWHuTvrdaEHwnXTZat2oLitWCc7ZT5Nmjw/IX7xWnVGKP/R9
 RmxOW/Xb5tBj2vpmViC61p3JFxeqvVVp4CWp0/3fJ2+pF+5MqusfPNAz17qLUifRFRWvdWFhR5J
 OG69JQPI8jYZnBJk3hqGtAgAo/OVeDy0Jl5TEiwte8qdOrbAwV9xptooTrXljidJ3iIs8FQNU4W
 +SqowYYutsCwnIg==
X-Developer-Key: i=rsworktech@outlook.com; a=openpgp;
 fpr=17AADD6726DDC58B8EE5881757670CCFA42CCF0A
X-Endpoint-Received: by B4 Relay for rsworktech@outlook.com/default with auth_id=219
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I found that bpf kselftest sockhash::test_txmsg_cork_hangs in
test_sockmap.c triggers a kernel NULL pointer dereference:

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
size(8192), which causes the while loop in splice_to_socket() to release
an uninitialized pipe buf.

The underlying cause is that this code assumes sk_msg_memcopy_from_iter()
will copy all bytes upon success but it actually might only copy part of
it.

This series change sk_msg_memcopy_from_iter() to return copied bytes on
success and tcp_bpf_sendmsg() to use the real copied bytes instead of
assuming all bytes gets copied.

Signed-off-by: Levi Zim <rsworktech@outlook.com>
---
Levi Zim (2):
      skmsg: return copied bytes in sk_msg_memcopy_from_iter
      tcp_bpf: fix copied value in tcp_bpf_sendmsg

 net/core/skmsg.c   | 5 +++--
 net/ipv4/tcp_bpf.c | 8 ++++----
 2 files changed, 7 insertions(+), 6 deletions(-)
---
base-commit: f1cd565ce57760923d5e0fbd9e9914b415c0620a
change-id: 20241130-tcp-bpf-sendmsg-ff3c9d84e693

Best regards,
-- 
Levi Zim <rsworktech@outlook.com>

