From: Shuqiao Zhang <stevenjoezhang@gmail.com>
Date: Fri, 18 Sep 2026 18:11:43 +0800
Subject: [PATCH] usb: gadget: rockusb: terminate full-speed descriptors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-rockusb-fs-descriptor-terminator-v1-1-144ffc0f3d33@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNQQ6CMBCF4auQWdukYKjoVYyLdjroaGzJTDEmh
 LtTdPe+zf8WUBImhUuzgNCHlXOqaA8N4MOnOxmO1dDZztlzOxjJ+Jo1mFFNJEXhqWQxheTNye/
 TRjr2Dk/B+QFqZhIa+fu7uN7+1jk8CcvehXXdAFw0Pj2EAAAA
X-Change-ID: 20260918-rockusb-fs-descriptor-terminator-0de356c7b6a8
To: Simon Glass <sjg@chromium.org>, Eddie Cai <eddie.cai.linux@gmail.com>, 
 u-boot@lists.u-boot-project.org
Cc: Lukasz Majewski <lukma@denx.de>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Quentin Schulz <u-boot@0leil.net>, Kever Yang <kever.yang@rock-chips.com>, 
 Marek Vasut <marek.vasut+usb@mailbox.org>, Tom Rini <trini@konsulko.com>, 
 Shuqiao Zhang <stevenjoezhang@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789726312; l=1530;
 i=stevenjoezhang@gmail.com; s=u-boot-shuqiao; h=from:subject:message-id;
 bh=297HYVzWoQyzaKEMPkmjlbobrcxRs62BISXqTzaxyhU=;
 b=0IkVa0ol1WYBkuYIIcm93Tk73Ux9PcG1uzhB8eTMJJmP9r3Wl2azNrlE5qSAhoKoIZghK+Ysf
 L+VVUgA3WQIDA8aktY9FyHPX/dGNUiS5a7C9mr7unsxIgMLokI5FmlW
X-Developer-Key: i=stevenjoezhang@gmail.com; a=ed25519;
 pk=Cbf095HhBi2UNpPtxc2MTfm3SXCBMpGzqw/m9h+Ykco=
X-Endpoint-Received: by B4 Relay for stevenjoezhang@gmail.com/u-boot-shuqiao with auth_id=1036
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

usb_descriptor_fillbuf() expects descriptor arrays to end with NULL.
The high-speed RockUSB array does, but the full-speed array does not.
Full-speed enumeration therefore reads beyond the array and treats
adjacent data as another descriptor pointer.

On a Luckfox Lyra Ultra (RK3506B), the adjacent interface descriptor
started with bytes 09 04 00 00. They were interpreted as pointer
0x00000409, causing a data abort in usb_descriptor_fillbuf().

Add the missing NULL terminator, matching the high-speed descriptor
array. After this change, RockUSB enumerates at full speed and
upgrade_tool can successfully read the eMMC.

Fixes: bf2b72bef14b ("usb: rockchip: add the rockusb gadget")
Signed-off-by: Shuqiao Zhang <stevenjoezhang@gmail.com>
---
 drivers/usb/gadget/f_rockusb.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/usb/gadget/f_rockusb.c b/drivers/usb/gadget/f_rockusb.c
index d679cdae97c..77a89b47d99 100644
--- a/drivers/usb/gadget/f_rockusb.c
+++ b/drivers/usb/gadget/f_rockusb.c
@@ -71,6 +71,7 @@ static struct usb_descriptor_header *rkusb_fs_function[] = {
 	(struct usb_descriptor_header *)&interface_desc,
 	(struct usb_descriptor_header *)&fs_ep_in,
 	(struct usb_descriptor_header *)&fs_ep_out,
+	NULL,
 };
 
 static struct usb_descriptor_header *rkusb_hs_function[] = {

---
base-commit: 211de43d0f954a00a490220c1aac9db298287c40
change-id: 20260918-rockusb-fs-descriptor-terminator-0de356c7b6a8

Best regards,
--  
Shuqiao Zhang <stevenjoezhang@gmail.com>

