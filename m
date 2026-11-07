From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 07 Nov 2026 16:46:40 +0800
Subject: [PATCH] firmware/sysfb: Avoid simple-framebuffer behind DT PCI
 host bridges
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-sysfb-dt-pci-efifb-v1-1-86d6c598671a@iscas.ac.cn>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqEMAyF4atI1gbaOqjMVQYXto0aFyqNilK8+
 1Rdfg/eH0EoMAl8swiBdhaepwSdZ+CGduoJ2SeDUabUWlUop3QW/YqLY6SOb1SFVbUn/7EG0nE
 JaT+e6K95LZsdya13Ca7rDywKGgR2AAAA
X-Change-ID: 20261107-sysfb-dt-pci-efifb-d73b08ded4b2
To: Ard Biesheuvel <ardb@kernel.org>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Thomas Zimmermann <tzimmermann@suse.de>, 
 Javier Martinez Canillas <javierm@redhat.com>, Borislav Petkov <bp@suse.de>, 
 Simona Vetter <simona.vetter@ffwll.ch>
Cc: linux-efi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-riscv@lists.infradead.org, 
 Han Gao <rabenda.cn@gmail.com>, stable@vger.kernel.org, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794041216; l=3936;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=kYFDOzF/Itut71CnG8RI8WDwvweu0YIXUO3C925lonU=;
 b=f49pP12LVp3nDhY5/qNCdRrn7GKGKv+PAeF7rRNnQhocxFGvzzftFz+q/x/2lTZdiAgXP2VPM
 Spx0r81cSHOD19AjA6XvuruJdovxQmXrcjLGkzR1exrcTYj1jtHjwTP
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With SYSFB_SIMPLEFB, sysfb registers a simple-framebuffer device that
claims the framebuffer memory when it is added. On DT systems, the PCI
host bridge may probe later and then fails to claim its memory window.
On QEMU RISC-V virt with EDK2, a bochs-display and pci-host-generic
built as a module:

  [    0.703813] pci-host-generic 30000000.pci: resource collision: [mem 0x40000000-0x7fffffff] conflicts with BOOTFB [mem 0x40000000-0x403e7fff]

In that case, register an efi-framebuffer device instead. It claims no
memory before it probes, and commit 64c8a0cd0a53 ("efi/arm: Defer probe
of PCIe backed efifb on DT systems") makes it wait for the host bridge.

Tested on a HiFive Unmatched with EDK2 and a PCIe graphics card, and on
QEMU.

Fixes: 8633ef82f101 ("drivers/firmware: consolidate EFI framebuffer setup for all arches")
Cc: stable@vger.kernel.org
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
In QEMU, efifb takes over with SYSFB_SIMPLEFB and efidrm without it.
With pci-host-generic built in, simpledrm is still used.
---
 drivers/firmware/efi/sysfb_efi.c | 16 ++++++++++++++++
 drivers/firmware/sysfb.c         |  8 +++++++-
 include/linux/sysfb.h            |  6 ++++++
 3 files changed, 29 insertions(+), 1 deletion(-)

diff --git a/drivers/firmware/efi/sysfb_efi.c b/drivers/firmware/efi/sysfb_efi.c
index 2338de73c62c..5c2cb87178ff 100644
--- a/drivers/firmware/efi/sysfb_efi.c
+++ b/drivers/firmware/efi/sysfb_efi.c
@@ -421,6 +421,22 @@ __init void sysfb_apply_efi_quirks(struct screen_info *si)
 		dmi_check_system(efifb_dmi_swap_width_height);
 }
 
+/* Returns true if the EFI framebuffer is in a DT PCI host bridge window */
+__init bool sysfb_efifb_behind_dt_pci(const struct screen_info *si)
+{
+	struct device_node *np;
+
+	if (si->orig_video_isVGA != VIDEO_TYPE_EFI || !IS_ENABLED(CONFIG_PCI))
+		return false;
+
+	np = find_pci_overlap_node();
+	if (!np)
+		return false;
+
+	of_node_put(np);
+	return true;
+}
+
 __init void sysfb_set_efifb_fwnode(const struct screen_info *si, struct platform_device *pd)
 {
 	if (si->orig_video_isVGA == VIDEO_TYPE_EFI && IS_ENABLED(CONFIG_PCI)) {
diff --git a/drivers/firmware/sysfb.c b/drivers/firmware/sysfb.c
index 8833582c1883..8853a74560b9 100644
--- a/drivers/firmware/sysfb.c
+++ b/drivers/firmware/sysfb.c
@@ -164,8 +164,14 @@ static __init int sysfb_init(void)
 		goto unlock_mutex;
 	}
 
-	/* try to create a simple-framebuffer device */
+	/*
+	 * Try to create a simple-framebuffer device. It claims the memory
+	 * when it is added, so a DT PCI host bridge that probes later would
+	 * fail. Use an efi-framebuffer device there; it waits for the bridge.
+	 */
 	compatible = sysfb_parse_mode(si, &mode);
+	if (compatible && !parent && sysfb_efifb_behind_dt_pci(si))
+		compatible = false;
 	if (compatible) {
 		pd = sysfb_create_simplefb(si, &mode, parent);
 		if (!IS_ERR(pd))
diff --git a/include/linux/sysfb.h b/include/linux/sysfb.h
index ed23d6516223..b136fdebc746 100644
--- a/include/linux/sysfb.h
+++ b/include/linux/sysfb.h
@@ -95,6 +95,7 @@ static inline bool sysfb_handles_screen_info(void)
 
 extern struct efifb_dmi_info efifb_dmi_list[];
 void sysfb_apply_efi_quirks(struct screen_info *si);
+bool sysfb_efifb_behind_dt_pci(const struct screen_info *si);
 void sysfb_set_efifb_fwnode(const struct screen_info *si, struct platform_device *pd);
 
 #else /* CONFIG_EFI */
@@ -103,6 +104,11 @@ static inline void sysfb_apply_efi_quirks(struct screen_info *si)
 {
 }
 
+static inline bool sysfb_efifb_behind_dt_pci(const struct screen_info *si)
+{
+	return false;
+}
+
 static inline void sysfb_set_efifb_fwnode(const struct screen_info *si,
 					  struct platform_device *pd)
 {

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261107-sysfb-dt-pci-efifb-d73b08ded4b2

Best regards,
--  
Han Gao <gaohan@iscas.ac.cn>

