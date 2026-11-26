From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 16:57:33 +0000
Subject: [PATCH RFC] media: doc: dev-encoder: Define CAPTURE sizeimage
 across OUTPUT changes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-b4-v4l2-enc-sizeimage-v1-1-dd2cb99bd717@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQrCMBBFr1L+2gGThmrdCh7ArbjoxFFHNEqmF
 rH07kZdvs9/b4RJVjGsqhFZBjW9pwJuViGeu3QS0kNh+LlvnPMNcaAhXD1JimT6Fr115bRsI4e
 aF4FbRnEfWY76+nV32G7W2P9He/JFYv8tYpo+V+2VLH4AAAA=
X-Change-ID: 20261126-b4-v4l2-enc-sizeimage-89cb43b74b9b
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: Tomasz Figa <tfiga@chromium.org>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795712252; l=2845;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=XKGgebnQg4fTpw0GKxAwBfwheI/TATP21n+3dmlxlw4=;
 b=BtgJpIITvXnpZo8HC5f0uWbkNs9IXNi/JXpL+4BP/Xuz5sIw/9XZeJ+7GoW/u9iembj1tQvuK
 IYOYmnjMQ0lC0ODVE1wBA2aIi7mKceVuBQiaSUqmersHlSDTeQXSOdg
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The encoder sets the CAPTURE width and height from the OUTPUT format,
but the specification doesn't say what happens to sizeimage then. A
client leaving sizeimage to the encoder (0) gets a size for the coded
size at the time of the CAPTURE S_FMT, usually the default resolution,
as the OUTPUT format is set later.

Document that setting the OUTPUT format updates the coded size, and a
sizeimage chosen by the encoder with it. A size requested by the client
is not reduced, so clients setting one keep their buffers.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Spec proposal asked for in the review of the Hantro JPEG encoder
fixes [1].

[1] https://lore.kernel.org/r/7a5a79bf8e1bfe698b7a49aa9580eb3858c25993.camel@collabora.com

Today vicodec, allegro and iris ignore the client's sizeimage; venus and
wave5 recompute or raise it on OUTPUT S_FMT; hantro, coda, mtk-vcodec and
s5p-mfc never update it. No driver change here.

Open point: a G_FMT/S_FMT round trip (v4l2-ctl) passes the old default
back as a non-zero sizeimage, so it then counts as the client's choice.

Developed with Claude (Anthropic), which wrote the text and the commit
message. I reviewed it.
---
 Documentation/userspace-api/media/v4l/dev-encoder.rst | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/Documentation/userspace-api/media/v4l/dev-encoder.rst b/Documentation/userspace-api/media/v4l/dev-encoder.rst
index cdad276d00bc..64f1297dab3f 100644
--- a/Documentation/userspace-api/media/v4l/dev-encoder.rst
+++ b/Documentation/userspace-api/media/v4l/dev-encoder.rst
@@ -156,7 +156,8 @@ Initialization
 
      ``sizeimage``
          desired size of ``CAPTURE`` buffers; the encoder may adjust it to
-         match hardware requirements.
+         match hardware requirements. If 0, the encoder chooses it for the
+         coded size and again when the coded size changes, see step 3.
 
      ``width``, ``height``
          ignored (read-only).
@@ -230,6 +231,12 @@ Initialization
      default values, based on the new resolution, as described in the next
      step.
 
+   * Setting the ``OUTPUT`` format sets the ``CAPTURE`` ``width`` and
+     ``height`` to the new coded size. A ``CAPTURE`` ``sizeimage`` chosen by
+     the encoder (the client passed 0, or the encoder ignores the client's
+     value) is chosen again for the new coded size. A ``sizeimage`` requested
+     by the client is not reduced.
+
 4. Set the raw frame interval on the ``OUTPUT`` queue via
    :c:func:`VIDIOC_S_PARM`. This also sets the coded frame interval on the
    ``CAPTURE`` queue to the same value.

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261126-b4-v4l2-enc-sizeimage-89cb43b74b9b

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

