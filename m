From: Keke Li <keke.li@amlogic.com>
Date: Wed, 18 Sep 2024 14:07:19 +0800
Subject: [PATCH v3 8/9] Documentation: media: add documentation file
 metafmt-c3-isp.rst
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-c3isp-v3-8-f774a39e6774@amlogic.com>
References: <20240918-c3isp-v3-0-f774a39e6774@amlogic.com>
In-Reply-To: <20240918-c3isp-v3-0-f774a39e6774@amlogic.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kieran.bingham@ideasonboard.com, 
 laurent.pinchart@ideasonboard.com, dan.scally@ideasonboard.com, 
 Keke Li <keke.li@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726639635; l=2506;
 i=keke.li@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=rUBd8+yUBOxLjKjvST1rZmnj73w+JEufrqFVM56kfIk=;
 b=umhZtXyWm5l3d16imxC3hRyCvlhDSs+brlI2w+6I5pg2d79B0fSj2Kor1GABxoWgSCO6axCwJ
 TNdX7IB2i1hCjo8HjSm3D9L0mZngrJQUAI95+jptQ3Dua/Jpu8xNMn1
X-Developer-Key: i=keke.li@amlogic.com; a=ed25519;
 pk=XxNPTsQ0YqMJLLekV456eoKV5gbSlxnViB1k1DhfRmU=
X-Endpoint-Received: by B4 Relay for keke.li@amlogic.com/20240902 with auth_id=204
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the file 'metafmt-c3-isp.rst' that documents
the meta format of c3-isp.

Signed-off-by: Keke Li <keke.li@amlogic.com>
---
 .../userspace-api/media/v4l/meta-formats.rst       |  1 +
 .../userspace-api/media/v4l/metafmt-c3-isp.rst     | 39 ++++++++++++++++++++++
 2 files changed, 40 insertions(+)

diff --git a/Documentation/userspace-api/media/v4l/meta-formats.rst b/Documentation/userspace-api/media/v4l/meta-formats.rst
index c6e56b5888bc..3a420747f6e7 100644
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
index 000000000000..bbaf3542c1ca
--- /dev/null
+++ b/Documentation/userspace-api/media/v4l/metafmt-c3-isp.rst
@@ -0,0 +1,39 @@
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
+3A statistics
+=============
+
+The C3 ISP can collect different statistics over an input Bayer frame.
+Those statistics are obtained from the "isp-stats" metadata capture video nodes,
+using the :c:type:`v4l2_meta_format` interface.
+They are formatted as described by the :c:type:`c3_isp_stats_info` structure.
+
+The statistics collected are  Auto-white balance,
+Auto-exposure and Auto-focus information.
+
+.. c3_isp_params_buffer
+
+Pipeline parameters
+===================
+
+The pipeline parameters are passed to the "isp-params" metadata
+output video nodes, using the :c:type:`v4l2_meta_format` interface. They are
+formatted as described by the :c:type:`c3_isp_params_buffer` structure.
+
+The structure c3_isp_params_buffer includes the necessary parameters
+required by the ISP.
+These parameters are written to the ISP hardware.
+
+Amlogic C3 ISP uAPI data types
+===============================
+
+.. kernel-doc:: drivers/media/platform/amlogic/c3-isp/include/uapi/c3-isp-config.h

-- 
2.46.1

