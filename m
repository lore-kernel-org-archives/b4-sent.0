From: Keke Li <keke.li@amlogic.com>
Date: Fri, 27 Dec 2024 15:09:18 +0800
Subject: [PATCH v5 09/10] Documentation: media: add documentation file
 metafmt-c3-isp.rst
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241227-c3isp-v5-9-c7124e762ff6@amlogic.com>
References: <20241227-c3isp-v5-0-c7124e762ff6@amlogic.com>
In-Reply-To: <20241227-c3isp-v5-0-c7124e762ff6@amlogic.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kieran.bingham@ideasonboard.com, 
 laurent.pinchart@ideasonboard.com, dan.scally@ideasonboard.com, 
 jacopo.mondi@ideasonboard.com, Keke Li <keke.li@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735283374; l=4958;
 i=keke.li@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=w4dz2vA7GDZeLpb0UA1sUBtNURUTWWS+GdXKL9y1Wec=;
 b=rIgXwVLTkcbMXuJd3DuyQzXsvzVkiXlqtXba5+hrjOmVWViYDDOWnc0yQdU7C4uK4hyK62mQa
 99smmSFNCU5B4arWNVBecbZHSgZbF++SpVovAs88SrbsVcYGur9u61f
X-Developer-Key: i=keke.li@amlogic.com; a=ed25519;
 pk=XxNPTsQ0YqMJLLekV456eoKV5gbSlxnViB1k1DhfRmU=
X-Endpoint-Received: by B4 Relay for keke.li@amlogic.com/20240902 with auth_id=204
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the file 'metafmt-c3-isp.rst' that documents
the meta format of c3-isp.

Signed-off-by: Keke Li <keke.li@amlogic.com>
---
 .../userspace-api/media/v4l/meta-formats.rst       |  1 +
 .../userspace-api/media/v4l/metafmt-c3-isp.rst     | 86 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 3 files changed, 88 insertions(+)

diff --git a/Documentation/userspace-api/media/v4l/meta-formats.rst b/Documentation/userspace-api/media/v4l/meta-formats.rst
index 86ffb3bc8ade..bb6876cfc271 100644
--- a/Documentation/userspace-api/media/v4l/meta-formats.rst
+++ b/Documentation/userspace-api/media/v4l/meta-formats.rst
@@ -12,6 +12,7 @@ These formats are used for the :ref:`metadata` interface only.
 .. toctree::
     :maxdepth: 1
 
+    metafmt-c3-isp
     metafmt-d4xx
     metafmt-generic
     metafmt-intel-ipu3
diff --git a/Documentation/userspace-api/media/v4l/metafmt-c3-isp.rst b/Documentation/userspace-api/media/v4l/metafmt-c3-isp.rst
new file mode 100644
index 000000000000..b15c40841266
--- /dev/null
+++ b/Documentation/userspace-api/media/v4l/metafmt-c3-isp.rst
@@ -0,0 +1,86 @@
+.. SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+
+.. _v4l2-meta-fmt-c3isp-stats:
+.. _v4l2-meta-fmt-c3isp-params:
+
+***********************************************************************
+V4L2_META_FMT_C3ISP_STATS ('CSTS'), V4L2_META_FMT_C3ISP_PARAMS ('CPRM')
+***********************************************************************
+
+.. c3_isp_stats_info
+
+3A Statistics
+=============
+
+The C3 ISP can collect different statistics over an input Bayer frame.
+Those statistics are obtained from the "c3-isp-stats" metadata capture video nodes,
+using the :c:type:`v4l2_meta_format` interface.
+They are formatted as described by the :c:type:`c3_isp_stats_info` structure.
+
+The statistics collected are  Auto-white balance,
+Auto-exposure and Auto-focus information.
+
+.. c3_isp_params_cfg
+
+Configuration Parameters
+========================
+
+The configuration parameters are passed to the c3-isp-params metadata output video node,
+using the :c:type:`v4l2_meta_format` interface. Rather than a single struct containing
+sub-structs for each configurable area of the ISP, parameters for the C3-ISP
+are defined as distinct structs or "blocks" which may be added to the data
+member of :c:type:`c3_isp_params_cfg`. Userspace is responsible for
+populating the data member with the blocks that need to be configured by the driver, but
+need not populate it with **all** the blocks, or indeed with any at all if there
+are no configuration changes to make. Populated blocks **must** be consecutive
+in the buffer. To assist both userspace and the driver in identifying the
+blocks each block-specific struct embeds
+:c:type:`c3_isp_params_block_header` as its first member and userspace
+must populate the type member with a value from
+:c:type:`c3_isp_params_block_type`. Once the blocks have been populated
+into the data buffer, the combined size of all populated blocks shall be set in
+the data_size member of :c:type:`c3_isp_params_cfg`. For example:
+
+.. code-block:: c
+
+	struct c3_isp_params_cfg *params =
+		(struct c3_isp_params_cfg *)buffer;
+
+	params->version = C3_ISP_PARAM_BUFFER_V0;
+	params->data_size = 0;
+
+	void *data = (void *)params->data;
+
+	struct c3_isp_params_awb_gains *gains =
+		(struct c3_isp_params_awb_gains *)data;
+
+	gains->header.type = C3_ISP_PARAMS_BLOCK_AWB_GAINS;
+	gains->header.flags = C3_ISP_PARAMS_BLOCK_FL_ENABLE;
+	gains->header.size = sizeof(struct c3_isp_params_awb_gains);
+
+	gains->gr_gain = 256;
+	gains->r_gain = 256;
+	gains->b_gain = 256;
+	gains->gb_gain = 256;
+
+	data += sizeof(struct c3_isp__params_awb_gains);
+	params->data_size += sizeof(struct c3_isp_params_awb_gains);
+
+	struct c3_isp_params_awb_config *awb_cfg =
+		(struct c3_isp_params_awb_config *)data;
+
+	awb_cfg->header.type = C3_ISP_PARAMS_BLOCK_AWB_CONFIG;
+	awb_cfg->header.flags = C3_ISP_PARAMS_BLOCK_FL_ENABLE;
+	awb_cfg->header.size = sizeof(struct c3_isp_params_awb_config);
+
+	awb_cfg->tap_point = C3_ISP_AWB_STATS_TAP_BEFORE_WB;
+	awb_cfg->satur = 1;
+	awb_cfg->horiz_zones_num = 32;
+	awb_cfg->vert_zones_num = 24;
+
+	params->data_size += sizeof(struct c3_isp_params_awb_config);
+
+Amlogic C3 ISP uAPI data types
+===============================
+
+.. kernel-doc:: include/uapi/linux/media/amlogic/c3-isp-config.h
diff --git a/MAINTAINERS b/MAINTAINERS
index d92427630bfa..b2626a370cc0 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1248,6 +1248,7 @@ M:	Keke Li <keke.li@amlogic.com>
 L:	linux-media@vger.kernel.org
 S:	Maintained
 F:	Documentation/devicetree/bindings/media/amlogic,c3-isp.yaml
+F:	Documentation/userspace-api/media/v4l/metafmt-c3-isp.rst
 F:	drivers/media/platform/amlogic/c3/isp/
 F:	include/uapi/linux/media/amlogic/
 

-- 
2.47.1

