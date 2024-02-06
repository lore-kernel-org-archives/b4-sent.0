From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 06 Feb 2024 11:08:26 +0100
Subject: [PATCH v9 3/7] of: property: add device link support for
 io-backends
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240206-iio-backend-v9-3-df66d159c000@analog.com>
References: <20240206-iio-backend-v9-0-df66d159c000@analog.com>
In-Reply-To: <20240206-iio-backend-v9-0-df66d159c000@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Frank Rowand <frowand.list@gmail.com>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, andy.shevchenko@gmail.com, 
 Rob Herring <robh@kernel.org>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707214121; l=1401;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=bQJmlHehrmhQX/B6Z0TUvJq43/kDkxEOa1pI4QQc4SY=;
 b=UU0+lxgXBC8Ha34Ecp2/uPc7l3fEvqfnNdJ44dMWJHdI23m5TVRZnd/TElq2+aNGIKa/e7DF7
 vj6ey2WutosD4xYc6AVwttXqOug94Mhu6On9dCNhAt+0ljoLmb1WDKo
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Olivier Moysan <olivier.moysan@foss.st.com>

Add support for creating device links out of more DT properties.

Signed-off-by: Olivier Moysan <olivier.moysan@foss.st.com>
Acked-by: Rob Herring <robh@kernel.org>
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/of/property.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/of/property.c b/drivers/of/property.c
index caa3e54aae13..0e91a5f4d0cb 100644
--- a/drivers/of/property.c
+++ b/drivers/of/property.c
@@ -1245,6 +1245,7 @@ DEFINE_SIMPLE_PROP(interconnects, "interconnects", "#interconnect-cells")
 DEFINE_SIMPLE_PROP(iommus, "iommus", "#iommu-cells")
 DEFINE_SIMPLE_PROP(mboxes, "mboxes", "#mbox-cells")
 DEFINE_SIMPLE_PROP(io_channels, "io-channels", "#io-channel-cells")
+DEFINE_SIMPLE_PROP(io_backends, "io-backends", "#io-backend-cells")
 DEFINE_SIMPLE_PROP(interrupt_parent, "interrupt-parent", NULL)
 DEFINE_SIMPLE_PROP(dmas, "dmas", "#dma-cells")
 DEFINE_SIMPLE_PROP(power_domains, "power-domains", "#power-domain-cells")
@@ -1335,6 +1336,7 @@ static const struct supplier_bindings of_supplier_bindings[] = {
 	{ .parse_prop = parse_iommu_maps, .optional = true, },
 	{ .parse_prop = parse_mboxes, },
 	{ .parse_prop = parse_io_channels, },
+	{ .parse_prop = parse_io_backends, },
 	{ .parse_prop = parse_interrupt_parent, },
 	{ .parse_prop = parse_dmas, .optional = true, },
 	{ .parse_prop = parse_power_domains, },

-- 
2.43.0

