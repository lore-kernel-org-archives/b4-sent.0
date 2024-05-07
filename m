From: Joel Granados <j.granados@samsung.com>
Date: Tue, 07 May 2024 10:40:39 +0200
Subject: [PATCH net-next] ax25: Remove superfuous "return" from
 ax25_ds_set_timer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240507-jag-fix_void_ret_ax25-v1-1-507fb246f192@samsung.com>
X-B4-Tracking: v=1; b=H4sIAAbpOWYC/x2MQQqAIBAAvxJ7bsEksfpKhIhutR0sVEKI/p50H
 JiZBxJFpgRT80CkmxOfoULXNuB2GzZC9pVBCtkLJTQedsOVi7lP9iZSNrZIhU4PnVDe+VWPUNs
 rUpX+7wyBMgYqGZb3/QAxNoBicQAAAA==
To: Joerg Reuter <jreuter@yaina.de>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-hams@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1502;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=dQzZAU/bAVlITUmjSe4Wlgex023rGgXtHdNKuKlNEBE=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGY56TMcXuz2REsRh/+4pIWo6jsuY6Qwkwzip
 jwFEVTLvwjGoIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmOekzAAoJELqXzVK3
 lkFPKhoL/25nUOLnvXhgHq5xRiJ8Ej/14vrShYBRPYQpM2FsDQdr+1aTDO+rbYrGsLncbC4tLCU
 KHMrI7oDjS6Mdl59SH0avR8d2BpA0Z8xH4JeQe1ThRH9u2JGi5G1jL/ObpPV487YwB3lAeqPoZm
 T7ONh3gyzKn7f0OvFk1Z+rM73hQvZchfXng4jFI0hVFIanhNZTUZhrrMh89B2HmcqersZgTdXmt
 Bj1cQxX2wfu8+7JTyDkt2wWttN9XQV2mAp3tP+7tgiZrLkTCnHl8jsIkoE+8mP4wbbldcKRi/me
 bUVv0+Itbzc7pxsVr2fmclidQzfUqNW2ULrPLL5ZnLisUnXtP7Q+5RGJuy+rxt5R1E7wDEYs9bT
 L/tleobFn97hXmsR1uIonaxK1WtYvIr8E7oVFzV38Ltf13/Fx3jKuyZkN7joYi3pWh+NA4wSnAc
 qwNtSPwC51O+p14SQP076eFhO7VMYIDnLRDD3gxuMHte8VnxVt5k1W2JwpSylYPYMHo9nEOMpT8
 lw=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the explicit call to "return" in the void ax25_ds_set_timer
function that was introduced in 78a7b5dbc060 ("ax.25: x.25: Remove the
now superfluous sentinel elements from ctl_table array").

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
I did not include a "Fixes:" tag as this (IMO) should not be backported
into a stable kernel. I'm assuming that net-next is going to be merged
into mainline as is and therefore I linked to a specific commit ID (get
back to me if I should do something different)

This comes after a review from Dave Carpenter [1] to an already accepted
patchset [2]

[1] https://lore.kernel.org/all/20240501-jag-sysctl_remset_net-v6-8-370b702b6b4a@samsung.com
[2] https://patchwork.kernel.org/project/netdevbpf/patch/20240501-jag-sysctl_remset_net-v6-1-370b702b6b4a@samsung.com/ 
---
 net/ax25/ax25_ds_timer.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/net/ax25/ax25_ds_timer.c b/net/ax25/ax25_ds_timer.c
index c50a58d9e368..c4f8adbf8144 100644
--- a/net/ax25/ax25_ds_timer.c
+++ b/net/ax25/ax25_ds_timer.c
@@ -55,7 +55,6 @@ void ax25_ds_set_timer(ax25_dev *ax25_dev)
 	ax25_dev->dama.slave_timeout =
 		msecs_to_jiffies(ax25_dev->values[AX25_VALUES_DS_TIMEOUT]) / 10;
 	mod_timer(&ax25_dev->dama.slave_timer, jiffies + HZ);
-	return;
 }
 
 /*

---
base-commit: 179a6f5df8dab7d027aa73a302d8506c6533e463
change-id: 20240507-jag-fix_void_ret_ax25-c78105dcdf79

Best regards,
-- 
Joel Granados <j.granados@samsung.com>

