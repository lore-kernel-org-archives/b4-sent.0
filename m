From: Rajan Yadav <rajanyadav0307@gmail.com>
Date: Wed, 04 Nov 2026 22:40:57 -0600
Subject: [PATCH 2/6] cpufreq: sun50i: Move nvmem cell reading into a helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-a133-series-v1-2-58217cb33a87@gmail.com>
References: <20261104-a133-series-v1-0-58217cb33a87@gmail.com>
In-Reply-To: <20261104-a133-series-v1-0-58217cb33a87@gmail.com>
To: Yangtao Li <tiny.windzz@gmail.com>, Viresh Kumar <vireshk@kernel.org>, 
 Nishanth Menon <nm@ti.com>, Stephen Boyd <sboyd@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Cody Eksal <masterr3c0rd@epochal.quest>, 
 Alexander Sverdlin <alex@sverdlin.org>, kernel test robot <lkp@intel.com>, 
 Rajan Yadav <rajanyadav0307@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793853656; l=3211;
 i=rajanyadav0307@gmail.com; s=20261103; h=from:subject:message-id;
 bh=jug1cYQuSv5vtD26KyGAcWUzxwXZeSilBxENXC4nAHg=;
 b=k0dIIHjmW7+QmHhHfNI7sv6p4fN6fPT5z/URspyr/6RQHO8f1lmPqeO5DKL27skarbEWmIzqG
 dyveJDl+NJ4BHE0MldP9sop/vfM5Jg6T/yKTwlavNrJkql/F2zTG5q/
X-Developer-Key: i=rajanyadav0307@gmail.com; a=ed25519;
 pk=4ZPeiP5qrv2b44q/Obxi2koUS70Q6npbttJnpUoTlgg=
X-Endpoint-Received: by B4 Relay for rajanyadav0307@gmail.com/20261103 with auth_id=1391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The A133 speed grade needs several efuse cells, but the cell reading
is open coded in sun50i_cpufreq_get_efuse() for a single cell. Move it
into sun50i_cpufreq_read_cell(), which takes the cell name, so the next
patch can read the A133 cells by name.

No functional change: the existing users read the first cell, as
before, with the same length check, byte order and error message. The
raw bytes are now held in a __le32, the type le32_to_cpu() expects,
which also removes the sparse warning "cast to restricted __le32" that
the kernel test robot reported.

Claude Code (Anthropic) drafted this refactor and its message; I
reviewed and tested it.

Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202603021703.aBD0w99y-lkp@intel.com/
Signed-off-by: Rajan Yadav <rajanyadav0307@gmail.com>
---
 drivers/cpufreq/sun50i-cpufreq-nvmem.c | 55 ++++++++++++++++++++--------------
 1 file changed, 33 insertions(+), 22 deletions(-)

diff --git a/drivers/cpufreq/sun50i-cpufreq-nvmem.c b/drivers/cpufreq/sun50i-cpufreq-nvmem.c
index 9261d148a16..34c0897c22c 100644
--- a/drivers/cpufreq/sun50i-cpufreq-nvmem.c
+++ b/drivers/cpufreq/sun50i-cpufreq-nvmem.c
@@ -31,6 +31,34 @@ struct sunxi_cpufreq_data {
 	u32 (*efuse_xlate)(u32 speedbin);
 };
 
+static int sun50i_cpufreq_read_cell(struct device *cpu_dev,
+				    struct device_node *np, const char *id,
+				    u32 *value)
+{
+	struct nvmem_cell *cell;
+	void *buf;
+	size_t len;
+	__le32 tmp = 0;
+
+	cell = of_nvmem_cell_get(np, id);
+	if (IS_ERR(cell))
+		return dev_err_probe(cpu_dev, PTR_ERR(cell),
+				     "Could not get nvmem cell\n");
+
+	buf = nvmem_cell_read(cell, &len);
+	nvmem_cell_put(cell);
+	if (IS_ERR(buf))
+		return PTR_ERR(buf);
+
+	if (len <= 4)
+		memcpy(&tmp, buf, len);
+	*value = le32_to_cpu(tmp);
+
+	kfree(buf);
+
+	return 0;
+}
+
 static u32 sun50i_h6_efuse_xlate(u32 speedbin)
 {
 	u32 efuse_value;
@@ -191,12 +219,9 @@ static bool dt_has_supported_hw(void)
 static int sun50i_cpufreq_get_efuse(void)
 {
 	const struct sunxi_cpufreq_data *opp_data;
-	struct nvmem_cell *speedbin_nvmem;
 	const struct of_device_id *match;
 	struct device *cpu_dev;
-	void *speedbin_ptr;
-	u32 speedbin = 0;
-	size_t len;
+	u32 speedbin;
 	int ret;
 
 	cpu_dev = get_cpu_device(0);
@@ -214,25 +239,11 @@ static int sun50i_cpufreq_get_efuse(void)
 
 	opp_data = match->data;
 
-	speedbin_nvmem = of_nvmem_cell_get(np, NULL);
-	if (IS_ERR(speedbin_nvmem))
-		return dev_err_probe(cpu_dev, PTR_ERR(speedbin_nvmem),
-				     "Could not get nvmem cell\n");
-
-	speedbin_ptr = nvmem_cell_read(speedbin_nvmem, &len);
-	nvmem_cell_put(speedbin_nvmem);
-	if (IS_ERR(speedbin_ptr))
-		return PTR_ERR(speedbin_ptr);
-
-	if (len <= 4)
-		memcpy(&speedbin, speedbin_ptr, len);
-	speedbin = le32_to_cpu(speedbin);
-
-	ret = opp_data->efuse_xlate(speedbin);
-
-	kfree(speedbin_ptr);
+	ret = sun50i_cpufreq_read_cell(cpu_dev, np, NULL, &speedbin);
+	if (ret)
+		return ret;
 
-	return ret;
+	return opp_data->efuse_xlate(speedbin);
 };
 
 static int sun50i_cpufreq_nvmem_probe(struct platform_device *pdev)

-- 
2.34.1

