From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH 0/2] (no cover subject)
Date: Sun, 14 Jun 2026 00:36:10 -0500
Message-Id: <20260614-b4-disp-818d6bda-v1-0-cf39a3615085@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMo9LmoC/x3MQQqAIBBA0avIrBtQCbOuEi3UmWo2FQoRSHdPW
 r7F/xUKZ+ECk6qQ+ZYi59FgOgVpD8fGKNQMVlunnekx9khSLvTGk4sU0NM66nGwIbGDll2ZV3n
 +5by87wfU3PWSYgAAAA==
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-kernel@vger.kernel.org, Hans de Goede <hansg@kernel.org>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>, linux-input@vger.kernel.org, 
 Andrew Duggan <aduggan@synaptics.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781415370; l=3216;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=oWzqgZ7CL6oPYCU6oE8l+W2cIUxxJetbxweA08XVCxU=;
 b=lHKBMfkDxuxX/3b3+4HtYPWm9RtM+VUakuNJwAPq3f6QI0Uk1pOwzv5dU8dElshbkTp06B9X3
 letACR/8LJCDu1cQdHcn8ouzFQcissLWjZn3dnobXCP1Hw6UPOHKgMH
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From be2c4843f6145374f28edd25cef43c9373542874 Mon Sep 17 00:00:00 2001
Message-ID: <cover.1781415009.git.hexlabsecurity@proton.me>
From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sun, 14 Jun 2026 00:30:09 -0500
Subject: [PATCH 0/2] Input: synaptics-rmi4 - fix out-of-bounds keymap access on large GPIO counts

The RMI4 F3A and F30 function handlers size their GPIO/LED key map to
min(device_gpio_count, TRACKSTICK_RANGE_END) == at most 6 entries, but
then consume that map with the full, unclamped device-reported count in
two places: the attention-interrupt report loop, and input->keycodemax
(while input->keycode points at the small allocation).

A device that reports a GPIO/LED count greater than 6 therefore yields a
key map of at most 12 bytes that is indexed up to count-1:

  - rmi_f3a_attention() / rmi_f30_attention() read gpio[led]_key_map[i]
    out of bounds on every attention interrupt (device-triggered), and

  - the input core's default keymap ioctls bound the index only against
    keycodemax, so EVIOCGKEYCODE reads adjacent slab memory back to user
    space and EVIOCSKEYCODE writes a caller-controlled u16 past the
    allocation -- a controlled out-of-bounds heap write reachable by any
    process that can open the evdev node.

Both handlers have the same shape; F3A was copied from F30. Patch 1 fixes
F3A, patch 2 fixes F30. The one-line fix in each sizes the key map to the
full device count; the mapping loop is unchanged (it still populates only
the first min(count, 6) entries, the rest stay KEY_RESERVED and are
skipped on report), and keycodemax now matches the allocation, closing
the interrupt and both ioctl paths.

Reproduced with KASAN on a faithful in-kernel model of each handler
(kmalloc-16 bucket, 12-byte request, reported count = 127):

  # without the patch -- attention read path
  BUG: KASAN: slab-out-of-bounds in rmi_f3a_attention
  Read of size 2 ... 0 bytes to the right of allocated 12-byte region
    ... cache kmalloc-16

  # without the patch -- EVIOCSKEYCODE write path
  BUG: KASAN: slab-out-of-bounds ...
  Write of size 2 ... 0 bytes to the right of allocated 12-byte region

  # with the patch (key map sized to the full count): clean
  # benign device (reported count <= 6): clean

The full read and write splats and a 32/64-bit ASan model of the same
geometry are available on request.

Bryam Vargas (2):
  Input: synaptics-rmi4 - bound the F3A keymap to the GPIO count
  Input: synaptics-rmi4 - bound the F30 keymap to the GPIO/LED count

 drivers/input/rmi4/rmi_f30.c | 2 +-
 drivers/input/rmi4/rmi_f3a.c | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
---
Bryam Vargas (2):
      Input: synaptics-rmi4 - bound the F3A keymap to the GPIO count
      Input: synaptics-rmi4 - bound the F30 keymap to the GPIO/LED count

 drivers/input/rmi4/rmi_f30.c | 2 +-
 drivers/input/rmi4/rmi_f3a.c | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260614-b4-disp-818d6bda-8df90972ace6

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

