From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 21 Nov 2023 11:20:15 +0100
Subject: [PATCH 02/12] of: property: add device link support for
 io-backends
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231121-dev-iio-backend-v1-2-6a3d542eba35@analog.com>
References: <20231121-dev-iio-backend-v1-0-6a3d542eba35@analog.com>
In-Reply-To: <20231121-dev-iio-backend-v1-0-6a3d542eba35@analog.com>
To: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-iio@vger.kernel.org
Cc: Olivier MOYSAN <olivier.moysan@foss.st.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Frank Rowand <frowand.list@gmail.com>, Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700562016; l=1344;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=FN56N4bRgP7DSXQFw9VBSMu8KBn7uhCOtdkMxYwRVGo=;
 b=9P9DkFOjJlA87bAEaTzYVCxeiFrFxsqhruoD2Cj8TfiXTVFRdTcYH3Qw5P/Tq1x7Qczfi2yKB
 skhzbrDMdbjChTfL1jAZx0G/TbOKrbAh7dRl/k6Nc7QO6ooTB6aRZy9
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Olivier Moysan <olivier.moysan@foss.st.com>

Add support for creating device links out of more DT properties.

Signed-off-by: Olivier Moysan <olivier.moysan@foss.st.com>
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/of/property.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/of/property.c b/drivers/of/property.c
index cf8dacf3e3b8..40a157daf08f 100644
--- a/drivers/of/property.c
+++ b/drivers/of/property.c
@@ -1244,6 +1244,7 @@ DEFINE_SIMPLE_PROP(interconnects, "interconnects", "#interconnect-cells")
 DEFINE_SIMPLE_PROP(iommus, "iommus", "#iommu-cells")
 DEFINE_SIMPLE_PROP(mboxes, "mboxes", "#mbox-cells")
 DEFINE_SIMPLE_PROP(io_channels, "io-channel", "#io-channel-cells")
+DEFINE_SIMPLE_PROP(io_backends, "io-backends", NULL)
 DEFINE_SIMPLE_PROP(interrupt_parent, "interrupt-parent", NULL)
 DEFINE_SIMPLE_PROP(dmas, "dmas", "#dma-cells")
 DEFINE_SIMPLE_PROP(power_domains, "power-domains", "#power-domain-cells")
@@ -1333,6 +1334,7 @@ static const struct supplier_bindings of_supplier_bindings[] = {
 	{ .parse_prop = parse_iommu_maps, .optional = true, },
 	{ .parse_prop = parse_mboxes, },
 	{ .parse_prop = parse_io_channels, },
+	{ .parse_prop = parse_io_backends, },
 	{ .parse_prop = parse_interrupt_parent, },
 	{ .parse_prop = parse_dmas, .optional = true, },
 	{ .parse_prop = parse_power_domains, },

-- 
2.42.1

