From: Cory Keitz <ckeitz@amazon.com>
Date: Thu, 05 Mar 2026 14:40:13 +0000
Subject: [PATCH 2/2] i2c: qcom-cci: Add DT property for SCL clock
 stretching
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260305-cci-scl-stretch-v1-2-8412abc65745@amazon.com>
References: <20260305-cci-scl-stretch-v1-0-8412abc65745@amazon.com>
In-Reply-To: <20260305-cci-scl-stretch-v1-0-8412abc65745@amazon.com>
To: Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Robert Foss <rfoss@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Cory Keitz <ckeitz@amazon.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772721622; l=1731;
 i=ckeitz@amazon.com; s=20260304; h=from:subject:message-id;
 bh=OwT3G4Wpy7L8KSSJSz2LODppXx7Vr9o7XgiwykQqPqU=;
 b=Y/sFC7CPtrdfbIbHxNIKks1+lYC88LTW/5BKg8Nn+9ZeRLLWP+0geVubpKbswUAB3aHUnX7iR
 rKHVbnFZCpIDswR5NiCI6o6VOHOHtmBR5msi55ZTF6iU5XHPID42C/Q
X-Developer-Key: i=ckeitz@amazon.com; a=ed25519;
 pk=IWSPbPI9mzOdPU5zG2ROe/O75E4ckVxuBLNJVYVZCag=
X-Endpoint-Received: by B4 Relay for ckeitz@amazon.com/20260304 with auth_id=662
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CCI hardware supports an SCL clock stretch enable bit in the
MISC_CTL register, but the driver hardcodes it off for most SoC
variants. This makes the bus driver unstable for configurations which
rely on clock stretching. Notably, GMSL uses clock stretching to absorb
the latency of transaction forwarding across the link.

Add a per-master "qcom,scl-stretch-enable" boolean DT property that
ORs with the existing hw_params default, allowing clock stretching to
be enabled on individual CCI masters without affecting others.

Signed-off-by: Cory Keitz <ckeitz@amazon.com>
---
 drivers/i2c/busses/i2c-qcom-cci.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/i2c/busses/i2c-qcom-cci.c b/drivers/i2c/busses/i2c-qcom-cci.c
index 884055df1560..022c10b310a0 100644
--- a/drivers/i2c/busses/i2c-qcom-cci.c
+++ b/drivers/i2c/busses/i2c-qcom-cci.c
@@ -111,6 +111,7 @@ struct cci_master {
 	struct i2c_adapter adap;
 	u16 master;
 	u8 mode;
+	bool scl_stretch_en;
 	int status;
 	struct completion irq_complete;
 	struct cci *cci;
@@ -284,7 +285,8 @@ static int cci_init(struct cci *cci)
 		val = hw->tbuf;
 		writel(val, cci->base + CCI_I2C_Mm_SDA_CTL_2(i));
 
-		val = hw->scl_stretch_en << 8 | hw->trdhld << 4 | hw->tsp;
+		val = (hw->scl_stretch_en | cci->master[i].scl_stretch_en) << 8 |
+			hw->trdhld << 4 | hw->tsp;
 		writel(val, cci->base + CCI_I2C_Mm_MISC_CTL(i));
 	}
 
@@ -572,6 +574,9 @@ static int cci_probe(struct platform_device *pdev)
 				master->mode = I2C_MODE_FAST_PLUS;
 		}
 
+		master->scl_stretch_en =
+			of_property_read_bool(child, "qcom,scl-stretch-enable");
+
 		init_completion(&master->irq_complete);
 	}
 

-- 
2.47.3

