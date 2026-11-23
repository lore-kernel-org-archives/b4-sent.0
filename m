From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Mon, 23 Nov 2026 20:37:38 +0100
Subject: [PATCH v4 06/11] pmdomain: amlogic: meson-ee-pwrc: power up
 memories for boot-enabled domains
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-meson-drm-create-hdmitx-phy-v4-6-3fb94f5534ca@aliel.fr>
References: <20261123-meson-drm-create-hdmitx-phy-v4-0-3fb94f5534ca@aliel.fr>
In-Reply-To: <20261123-meson-drm-create-hdmitx-phy-v4-0-3fb94f5534ca@aliel.fr>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Vinod Koul <vkoul@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Ulf Hansson <ulfh@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-phy@lists.infradead.org, dri-devel@lists.freedesktop.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>, linux-pm@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2681;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=2pSroicxmn87L6WpeMI1TQ71NJdXRXfygd9gmAxHGRQ=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQzbLNL5sQ++6hzY5B5+Z/bsWLnPZw+y4ppPqnWyGbClfv
 s+zErU7SlkYxLgYZMUUWfrnWp54d/noma971FNg5rAygQxh4OIUgIkItTH8jzincSxhz4q5twuX
 X9r7263C0aH5T5X3rMO7Pm3v4VVifMzI8M080Kmb9bSV5dqwPqn5dx3e3PrKt7Lzk2+a0NGHcys
 2sAMA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a power domain is found already powered on at probe time (typically
the VPU domain left enabled by the bootloader), the driver registers the
genpd in the ON state with GENPD_FLAG_ALWAYS_ON and never calls
meson_ee_pwrc_on(). As a result, the memory power-down bits of the domain
are not touched.

pwrc_ee_is_powered_off() only checks the top-level sleep bit, so a
bootloader that enabled the VPU without waking every memory block
leaves those memories powered down, and nothing in the genpd framework
will wake them since pm_runtime_resume_and_get() is a no-op for an
always-on domain.

This is a preparatory change: a following patch drops the explicit
HHI_MEM_PD_REG0 write from the meson_dw_hdmi driver, which relies on the
power domain to power the HDMITX memory.

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 drivers/pmdomain/amlogic/meson-ee-pwrc.c | 19 ++++++++++++++-----
 1 file changed, 14 insertions(+), 5 deletions(-)

diff --git a/drivers/pmdomain/amlogic/meson-ee-pwrc.c b/drivers/pmdomain/amlogic/meson-ee-pwrc.c
index 338f70d77bf0..b3ae5cd7bea8 100644
--- a/drivers/pmdomain/amlogic/meson-ee-pwrc.c
+++ b/drivers/pmdomain/amlogic/meson-ee-pwrc.c
@@ -392,11 +392,21 @@ static int meson_ee_pwrc_off(struct generic_pm_domain *domain)
 	return 0;
 }
 
+static void meson_ee_pwrc_mem_power_up(struct meson_ee_pwrc_domain *dom)
+{
+	int i;
+
+	for (i = 0; i < dom->desc.mem_pd_count; i++)
+		regmap_update_bits(dom->pwrc->regmap_hhi,
+				   dom->desc.mem_pd[i].reg,
+				   dom->desc.mem_pd[i].mask, 0);
+}
+
 static int meson_ee_pwrc_on(struct generic_pm_domain *domain)
 {
 	struct meson_ee_pwrc_domain *pwrc_domain =
 		container_of(domain, struct meson_ee_pwrc_domain, base);
-	int i, ret;
+	int ret;
 
 	if (pwrc_domain->desc.top_pd)
 		regmap_update_bits(pwrc_domain->pwrc->regmap_ao,
@@ -404,10 +414,7 @@ static int meson_ee_pwrc_on(struct generic_pm_domain *domain)
 				   pwrc_domain->desc.top_pd->sleep_mask, 0);
 	udelay(20);
 
-	for (i = 0 ; i < pwrc_domain->desc.mem_pd_count ; ++i)
-		regmap_update_bits(pwrc_domain->pwrc->regmap_hhi,
-				   pwrc_domain->desc.mem_pd[i].reg,
-				   pwrc_domain->desc.mem_pd[i].mask, 0);
+	meson_ee_pwrc_mem_power_up(pwrc_domain);
 
 	udelay(20);
 
@@ -478,6 +485,8 @@ static int meson_ee_pwrc_init_domain(struct platform_device *pdev,
          * prepare/enable counters won't be in sync.
          */
 	if (dom->num_clks && dom->desc.is_powered_off && !dom->desc.is_powered_off(dom)) {
+		meson_ee_pwrc_mem_power_up(dom);
+
 		ret = clk_bulk_prepare_enable(dom->num_clks, dom->clks);
 		if (ret)
 			return ret;

-- 
2.56.1

