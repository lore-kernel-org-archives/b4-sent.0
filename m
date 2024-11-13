From: Manas <manas18244@iiitd.ac.in>
Date: Thu, 14 Nov 2024 04:14:25 +0530
Subject: [PATCH] Add string check in netlink_ack_tlv_fill
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241114-fix-netlink_ack_tlv_fill-v1-1-47798af4ac96@iiitd.ac.in>
X-B4-Tracking: v=1; b=H4sIAMgrNWcC/x2MQQqAIBAAvxJ7TmjNOvSVCLFca0ksVCKI/p50H
 JiZBxJFpgRD9UCkixMfoQDWFSybCSsJtoVBNlIhohKObxEoew67Nsuus7+0Y+8FKju3be9shx2
 U/IxU3H89Tu/7ATWBNE5qAAAA
X-Change-ID: 20241114-fix-netlink_ack_tlv_fill-14db336fd515
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>
Cc: Shuah Khan <shuah@kernel.org>, Anup Sharma <anupnewsmail@gmail.com>, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzbot+d4373fa8042c06cefa84@syzkaller.appspotmail.com, 
 Manas <manas18244@iiitd.ac.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731537875; l=1252;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=55t/60GTBCQ0um8FTkqO5lX7EGbdb4Ol8yhNWltdE64=;
 b=Dutv3+0ZVkkyixd98LfdaPQEUh3KmgL6tLg6uXmbTzGITq+LHuULss4o3k+J93nbqDZa3kCHY
 iBwnWQ0I9BCCuEPQX0vSxMaQLil+0fYwkpdds4/SALQSJiB4SXIWfeS
X-Developer-Key: i=manas18244@iiitd.ac.in; a=ed25519;
 pk=pXNEDKd3qTkQe9vsJtBGT9hrfOR7Dph1rfX5ig2AAoM=
X-Endpoint-Received: by B4 Relay for manas18244@iiitd.ac.in/20240813 with auth_id=196
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

netlink_ack_tlv_fill crashes when in_skb->data is an empty string. This
adds a check to prevent it.

Reported-by: syzbot+d4373fa8042c06cefa84@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=d4373fa8042c06cefa84
Signed-off-by: Manas <manas18244@iiitd.ac.in>
---
netlink_ack_tlv_fill crashes when in_skb->data is an empty string. This
adds a check to prevent it.
---
 net/netlink/af_netlink.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/netlink/af_netlink.c b/net/netlink/af_netlink.c
index 0a9287fadb47a2afaf0babe675738bc43051c5a7..ea205a4f81e9755a229d46a7e617ce0c090fe5e3 100644
--- a/net/netlink/af_netlink.c
+++ b/net/netlink/af_netlink.c
@@ -2205,7 +2205,7 @@ netlink_ack_tlv_fill(struct sk_buff *in_skb, struct sk_buff *skb,
 	if (!err)
 		return;
 
-	if (extack->bad_attr &&
+	if (extack->bad_attr && strlen(in_skb->data) &&
 	    !WARN_ON((u8 *)extack->bad_attr < in_skb->data ||
 		     (u8 *)extack->bad_attr >= in_skb->data + in_skb->len))
 		WARN_ON(nla_put_u32(skb, NLMSGERR_ATTR_OFFS,

---
base-commit: 2d5404caa8c7bb5c4e0435f94b28834ae5456623
change-id: 20241114-fix-netlink_ack_tlv_fill-14db336fd515

Best regards,
-- 
Manas <manas18244@iiitd.ac.in>

