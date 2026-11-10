From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Tue, 10 Nov 2026 09:03:26 +0000
Subject: [PATCH net] gtp: free the skb after handling an echo response
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-gtp-echo-rsp-leak-v1-1-192c032f3dfa@gmail.com>
X-B4-Tracking: v=1; b=H4sIAN3d8moC/x3MQQqAIBBA0avErBtQg4KuEi3MJh0KFZUIwrsnL
 d/i/xcyJaYMc/dCopszB98g+w6M094S8t4MSqhRSinQlohkXMCUI16kT5z0cGgzqm0fDLQuJjr
 4+Z8LeCqw1voBEyRO/2gAAAA=
To: pablo@netfilter.org, laforge@gnumonks.org, andrew+netdev@lunn.ch, 
 davem@davemloft.net, edumazet@kernel.org, kuba@kernel.org, 
 pabeni@redhat.com, joasantonio108@gmail.com
Cc: osmocom-net-gprs@lists.osmocom.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794301405; l=3733;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=R9TcIxYRIQLC36eXFKBEQ/zbPTM2JwmdjnAqri7utlE=;
 b=USEiUSTtzqnSdLf/+y3HR6JuvI4VGG9bRKewqbXKarWNZBPZtmD7tPcE1rq5inbOwayXH3Xhc
 QUiacOqhnsZDNrw2Y+AxQyPrTEc3pzMt1uxH2zbeqM4MqTRWLdXJhPK
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gtp0_handle_echo_resp() and gtp1u_handle_echo_resp() return the result
of genlmsg_multicast_netns() to gtp_encap_recv().  When the netlink
notification is delivered that result is 0, and gtp_encap_recv() treats
0 as "the skb has been consumed":

	switch (ret) {
	case 1:
		netdev_dbg(gtp->dev, "pass up to the process\n");
		break;
	case 0:
		break;
	case -1:
		netdev_dbg(gtp->dev, "GTP packet has been dropped\n");
		kfree_skb(skb);
		ret = 0;
		break;
	}

The echo response handlers only read from the skb and never free it or
pass it on, so every echo response that is reported to a listener on the
gtp multicast group leaks the skb.  Echo responses are handled for any
peer when the UDP sockets were created by the kernel, so a remote host
can leak memory on the receiver by sending GTP echo responses while a
process with CAP_NET_ADMIN is subscribed to the gtp multicast group, for
example a daemon that monitors echo responses.

The error paths do not leak but have a related problem.  -ENOMEM and the error from
genlmsg_multicast_netns() (-ESRCH when nobody listens) are not -1, so
they are returned unchanged to the UDP stack, which takes a negative
value from encap_rcv() as a request to resubmit the packet to the
protocol with that number.

Return -1 when the notification cannot be built, so that
gtp_encap_recv() drops the skb, and consume the skb once the
notification has been handed to netlink, whether or not anybody is
listening.

Found by LLM-assisted source review.

Fixes: d33bd757d362 ("gtp: Implement GTP echo request")
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
This issue was found with the help of an LLM-based code review tool
(Claude).  I checked the code paths by hand against v7.4-rc3 and
reviewed the fix myself.  It is build-tested only (W=1, arm64); I do
not have the hardware to test it at runtime.
---
 drivers/net/gtp.c | 22 ++++++++++++++--------
 1 file changed, 14 insertions(+), 8 deletions(-)

diff --git a/drivers/net/gtp.c b/drivers/net/gtp.c
index 1dd32e979cf5..85d1b0c46ecf 100644
--- a/drivers/net/gtp.c
+++ b/drivers/net/gtp.c
@@ -561,16 +561,19 @@ static int gtp0_handle_echo_resp(struct gtp_dev *gtp, struct sk_buff *skb)
 
 	msg = nlmsg_new(NLMSG_DEFAULT_SIZE, GFP_ATOMIC);
 	if (!msg)
-		return -ENOMEM;
+		return -1;
 
 	ret = gtp_genl_fill_echo(msg, 0, 0, 0, GTP_CMD_ECHOREQ, echo);
 	if (ret < 0) {
 		nlmsg_free(msg);
-		return ret;
+		return -1;
 	}
 
-	return genlmsg_multicast_netns(&gtp_genl_family, dev_net(gtp->dev),
-				       msg, 0, GTP_GENL_MCGRP, GFP_ATOMIC);
+	genlmsg_multicast_netns(&gtp_genl_family, dev_net(gtp->dev),
+				msg, 0, GTP_GENL_MCGRP, GFP_ATOMIC);
+	consume_skb(skb);
+
+	return 0;
 }
 
 static int gtp_proto_to_family(__u16 proto)
@@ -748,16 +751,19 @@ static int gtp1u_handle_echo_resp(struct gtp_dev *gtp, struct sk_buff *skb)
 
 	msg = nlmsg_new(NLMSG_DEFAULT_SIZE, GFP_ATOMIC);
 	if (!msg)
-		return -ENOMEM;
+		return -1;
 
 	ret = gtp_genl_fill_echo(msg, 0, 0, 0, GTP_CMD_ECHOREQ, echo);
 	if (ret < 0) {
 		nlmsg_free(msg);
-		return ret;
+		return -1;
 	}
 
-	return genlmsg_multicast_netns(&gtp_genl_family, dev_net(gtp->dev),
-				       msg, 0, GTP_GENL_MCGRP, GFP_ATOMIC);
+	genlmsg_multicast_netns(&gtp_genl_family, dev_net(gtp->dev),
+				msg, 0, GTP_GENL_MCGRP, GFP_ATOMIC);
+	consume_skb(skb);
+
+	return 0;
 }
 
 static int gtp_parse_exthdrs(struct sk_buff *skb, unsigned int *hdrlen)

---
base-commit: b3dfbde62cf1981c4638939c159dfd087b7a72e9
change-id: 20261110-gtp-echo-rsp-leak-7a3fac62bd3c

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

