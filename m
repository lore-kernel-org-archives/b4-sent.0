From: Michael Riesch <michael.riesch@wolfvision.net>
Subject: [PATCH RFC 0/4] media: v4l2-ctrls: add controls for complex lens
 controller devices
Date: Thu, 06 Apr 2023 16:31:09 +0200
Message-Id: <20230406-feature-controls-lens-v1-0-543189a680de@wolfvision.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAK3XLmQC/1XNQQrCMBCF4auUWTsYm0TFreAB3IqLJJ3aQEnKT
 C2F0rubihuXP7yPt4AQRxK4VAswTVFiTiUOuwpC59KLMDaloVa1VkYdsSU3vpkw5DRy7gV7SoL
 +bO3JNtoY7aBY74TQs0uh2/QP7f/QthuY2jh//x9wv13hua4fXIphSJQAAAA=
To: Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: libcamera-devel@lists.libcamera.org, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Matthias Fend <Matthias.Fend@wolfvision.net>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Michael Riesch <michael.riesch@wolfvision.net>
X-Mailer: b4 0.12.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1680791498; l=3101;
 i=michael.riesch@wolfvision.net; s=20230406; h=from:subject:message-id;
 bh=OJh4zaYpUGmBGJnTjRe4Hscxo/UtXSa7youeXVGyH7A=;
 b=6fXSMiSHAibecfHaIrXad2RhBLfWutwmqZTdnbta4uPO56oUCRTsDHvu1zXs4G8HVvItbgfTB
 rR/pb1r9qehDeEVBAjQrMlQ8BFuiowDdBdmHHo7YYKhWXdXYOiA9T/n
X-Developer-Key: i=michael.riesch@wolfvision.net; a=ed25519;
 pk=G03kuYHL670EcdsWaNfVA7KnHWmkSpj98XziQm/hjbk=
X-Endpoint-Received: by B4 Relay for michael.riesch@wolfvision.net/20230406 with auth_id=38
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

This patch series aims to add support for complex lens controllers in V4L2.
Complex lens controllers usually feature one focus lens and one (or more)
zoom lens(es), which are driven by stepper motors. As a consequence, a few
crucial differences to simple lens controllers (such as voice coil motor
(VCM) drivers, which are already well supported in V4L2) arise:

 - Focus and zoom are slow.

Compared to a simple VCM driver, which reacts almost instantaneously, the
stepper motors that control the lens groups may require some time to reach
their target position. Therefore, the control process in user space needs
to receive feedback on the current status of each lens group, such as the
current position and whether or not the lens group is moving. Patch 1/4
adds volatile and read-only status controls for each lens group.

 - The velocity of focus and zoom can be selected.

In contrast to a simple VCM driver, the stepper motors can move at
different velocities. Since the produced noise depends on the velocity, the
control process may want to optimize the chosen velocity. Also, some auto
focus algorithms use different velocities in different phases (e.g., a
coarse and fast scan vs. a slow and precise scan). Patch 2/4 adds speed
controls for the focus lens group and the zoom lens group.

 - Calibration may be required.

Since moving mechanical parts are involved, calibration is most likely
necessary. Patch 3/4 introduces controls to control calibration procedures.

In the scope of calibration, the relation between the lens positions may be
fine-tuned. This requires the ability to control the individual lenses and
gather feedback on their current status. Patch 4/4 introduces a pair of
controls for five zoom lenses. (Five is a placeholder here. The most
complex objective we had at hand happened to feature five zoom lenses.)

On the user space side, it is envisaged that libcamera operates the newly
introduced controls. Please note that no tests with libcamera have been
carried out yet, the integration will be discussed after the first round of
feedback to this RFC.

Looking forward to your comments!

---
Michael Riesch (4):
      media: v4l2-ctrls: add lens group status controls for zoom and focus
      media: v4l2-ctrls: add lens group speed controls for zoom and focus
      media: v4l2-ctrls: add lens calibration controls
      media: v4l2-ctrls: add controls for individual zoom lenses

 .../userspace-api/media/v4l/ext-ctrls-camera.rst   | 105 +++++++++++++++++++++
 drivers/media/v4l2-core/v4l2-ctrls-core.c          |   9 ++
 drivers/media/v4l2-core/v4l2-ctrls-defs.c          |  30 ++++++
 include/media/v4l2-ctrls.h                         |   2 +
 include/uapi/linux/v4l2-controls.h                 |  39 ++++++++
 include/uapi/linux/videodev2.h                     |   2 +
 6 files changed, 187 insertions(+)
---
base-commit: fe15c26ee26efa11741a7b632e9f23b01aca4cc6
change-id: 20230406-feature-controls-lens-b85575d3443a

Best regards,
-- 
Michael Riesch <michael.riesch@wolfvision.net>

