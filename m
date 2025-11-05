From: Yang Li <yang.li@amlogic.com>
Date: Wed, 05 Nov 2025 17:02:06 +0800
Subject: [PATCH] Bluetooth: iso: Fix UAF on iso_sock_disconn
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251105-kernel_panic-v1-1-88637054c6b9@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAI0SC2kC/x3MQQqAIBBA0avIrBM0E6OrRIToVENhohCBePek5
 Vv8XyBjIswwsQIJH8p0hwbZMXCHDTty8s3Qi15LKTQ/MQW81mgDOW6U9c4INYzCQ0tiwo3efzc
 vtX43iwIZXgAAAA==
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762333331; l=1549;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=S5BJh2ba2g9xJCkHYB8Rff1jMpJFLarygQDk7qfhCww=;
 b=0Es3hP455AD3QZnhIIAzJALsD1uJ+obbNHtlx9EHEvCMso1TC5723gpPHqHVWkrPn+X5+uRtK
 4cb2LTUXq+wBZHpUwMkaPne7ZL6T6dmNLUZnP66TvfICrPwaP8/jMfA
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

kernel panic: Unable to handle kernel read from unreadable
memory at virtual address 00000000000003d8

Call trace:
 iso_sock_disconn+0x110/0x1c8
 __iso_sock_close+0x50/0x164
 iso_sock_release+0x48/0xf0
 __sock_release+0x40/0xb4
 sock_close+0x18/0x28
 __fput+0xd8/0x28c
 __fput_sync+0x50/0x5c
 __arm64_sys_close+0x38/0x7c
 invoke_syscall+0x48/0x118
 el0_svc_common.constprop.0+0x40/0xe0
 do_el0_svc_compat+0x1c/0x34
 el0_svc_compat+0x30/0x88
 el0t_32_sync_handler+0x90/0x140
 el0t_32_sync+0x198/0x19c

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 net/bluetooth/iso.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/net/bluetooth/iso.c b/net/bluetooth/iso.c
index 74ec7d125c88..89c7700ceb81 100644
--- a/net/bluetooth/iso.c
+++ b/net/bluetooth/iso.c
@@ -838,14 +838,14 @@ static void __iso_sock_close(struct sock *sk)
 	case BT_CONNECT:
 	case BT_CONNECTED:
 	case BT_CONFIG:
-		if (iso_pi(sk)->conn->hcon)
+		if (iso_pi(sk)->conn && iso_pi(sk)->conn->hcon)
 			iso_sock_disconn(sk);
 		else
 			iso_chan_del(sk, ECONNRESET);
 		break;
 
 	case BT_CONNECT2:
-		if (iso_pi(sk)->conn->hcon &&
+		if (iso_pi(sk)->conn && iso_pi(sk)->conn->hcon &&
 		    (test_bit(HCI_CONN_PA_SYNC, &iso_pi(sk)->conn->hcon->flags) ||
 		    test_bit(HCI_CONN_PA_SYNC_FAILED, &iso_pi(sk)->conn->hcon->flags)))
 			iso_sock_disconn(sk);

---
base-commit: 2747d929617743ecba08eeeb310283b4be681383
change-id: 20251105-kernel_panic-73adc703480d

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

