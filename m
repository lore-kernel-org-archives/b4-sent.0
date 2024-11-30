From: Levi Zim <rsworktech@outlook.com>
Date: Sat, 30 Nov 2024 21:38:22 +0800
Subject: [PATCH net 1/2] skmsg: return copied bytes in
 sk_msg_memcopy_from_iter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241130-tcp-bpf-sendmsg-v1-1-bae583d014f3@outlook.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1296;
 i=rsworktech@outlook.com; h=from:subject:message-id;
 bh=+jh9LaMvNTwv+zmDx2vk37sFrN9lWR5dQyH5HZC8Q2M=;
 b=owEBbQKS/ZANAwAIAW87mNQvxsnYAcsmYgBnSxV+cY/4xWp+AOu+HS1pF3mD1lkW8ZroPbktI
 OGHl4YPTW+JAjMEAAEIAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCZ0sVfgAKCRBvO5jUL8bJ
 2O4mD/9uiFluDIQT5sursakLeOiycc85GUFuCghVJQyfsOzbd6i1STV1z0tniaX2ZFkcha+XtZK
 Tn/qA3C6do92pLsRW0VpVB2JpWJS/Bgh80SSj0AHo9pfAqH7Rz9Z1nwznelejLdKFwbPK86zvVN
 Nd8ar9fgT9f+lvptiLNjUefXXNU53Zv+yQpzZDM9/DWNFvBQ3MFltNWWTbi5NCPpxzoC/Eg243O
 NoON2+47hgJyprsrI+nyuSwZZGJLwXEw6zNPWPuoC0dkD6sO2qKgJWQ46QfWUQh+ciIHd7cTvpA
 T5oVR558KA1JDRt8a3prsYkXsGLDmeZ7TDiEzfYDXPZbuvDDuQaXcP9SqxY2i0moRHZqapRMUNo
 4ZYho5sDiVRM7L1lz3tUBUeWUH9JYgSOhCXmoP5IxkzAo22iDrd0ePZVAADcqcB15VtCkp6VgTT
 I5+DdO8cyNgomya2WVLTUKeXFxurvyBAE4BWyt+EGnhlZJLwfR7cQELw/JOYB/RIedqlAyr05bd
 b+vey1/eH12e3aRy/xMb6hOV4FbG8RczF7+Csj2WO8C+1lChytqCKRFus3On6S1OuO7KYKzZfZl
 oPG/UpE4AQ6/2R1qV2YdJz3h00IA3T2KTywVhdYFDcEbD3pYc5LWcAtW7FIs6HWzImeirVgX9TO
 6tB4maLwLVTPTCA==
X-Developer-Key: i=rsworktech@outlook.com; a=openpgp;
 fpr=17AADD6726DDC58B8EE5881757670CCFA42CCF0A
X-Endpoint-Received: by B4 Relay for rsworktech@outlook.com/default with auth_id=219
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Previously sk_msg_memcopy_from_iter returns the copied bytes from the
last copy_from_iter{,_nocache} call upon success.

This commit changes it to return the total number of copied bytes on
success.

Signed-off-by: Levi Zim <rsworktech@outlook.com>
---
 net/core/skmsg.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/net/core/skmsg.c b/net/core/skmsg.c
index e90fbab703b2db1da49068b5a53338ce7ff99087..a65c2e64645863b80ddd94c464d86fcc587b5c04 100644
--- a/net/core/skmsg.c
+++ b/net/core/skmsg.c
@@ -369,8 +369,8 @@ int sk_msg_memcopy_from_iter(struct sock *sk, struct iov_iter *from,
 			     struct sk_msg *msg, u32 bytes)
 {
 	int ret = -ENOSPC, i = msg->sg.curr;
+	u32 copy, buf_size, copied = 0;
 	struct scatterlist *sge;
-	u32 copy, buf_size;
 	void *to;
 
 	do {
@@ -397,6 +397,7 @@ int sk_msg_memcopy_from_iter(struct sock *sk, struct iov_iter *from,
 			goto out;
 		}
 		bytes -= copy;
+		copied += copy;
 		if (!bytes)
 			break;
 		msg->sg.copybreak = 0;
@@ -404,7 +405,7 @@ int sk_msg_memcopy_from_iter(struct sock *sk, struct iov_iter *from,
 	} while (i != msg->sg.end);
 out:
 	msg->sg.curr = i;
-	return ret;
+	return (ret < 0) ? ret : copied;
 }
 EXPORT_SYMBOL_GPL(sk_msg_memcopy_from_iter);
 

-- 
2.47.1

