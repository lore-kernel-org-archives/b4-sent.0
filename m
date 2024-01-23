From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 23 Jan 2024 16:14:26 +0100
Subject: [PATCH v7 5/9] of: property: add device link support for
 io-backends
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240123-iio-backend-v7-5-1bff236b8693@analog.com>
References: <20240123-iio-backend-v7-0-1bff236b8693@analog.com>
In-Reply-To: <20240123-iio-backend-v7-0-1bff236b8693@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Frank Rowand <frowand.list@gmail.com>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Saravana Kannan <saravanak@google.com>, Rob Herring <robh@kernel.org>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706022871; l=1401;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=TmMsWX73B4o1Dpuycs2q1norfXZ2MzGLcAxOfBi1JfU=;
 b=cg19qs7waKgHTCtX8Vk0w8wiIN8fThNkIARUOY7yBAyD8R+pKwV9vuZb+1s9bTbq3bpYAaI5W
 nfGn4QG4QB/BcJ8S4wSFRsmXo6vMyYUgL28Pos0vIgMU8xy1DLOzjF4
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
index bbf0dee2fb9c..44203e42f0e2 100644
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

