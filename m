From: Jaidev Shastri <jaidevshastri@vt.edu>
Subject: [PATCH 0/6] vt: keyboard: make the kbd_event_lock ordering
 explicit
Date: Mon, 21 Sep 2026 21:28:13 -0400
Message-Id: <20260921-mb-keyboard-v1-0-d170228b80c0@vt.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAK3ZsWoC/yXMwQ6CMBAE0F8he3YNtGCDv2I8tGWRaixkVwmE8
 O+2eHyTmdlAiAMJXIsNmOYgYYwJ1akAP9j4IAxdMqhSXcpWVfh2+KLVjZY7NH3datXoRhuCtJi
 Y+rAcb7f73/J1T/KffJEbzgqhYxv9kKODszlrZF/Dvv8AYqnfzI8AAAA=
X-Change-ID: 20260921-mb-keyboard-7f493253537e
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040498; l=1714;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=dFylFEPnR97J+B4KdpVrhI6g4QkdGREbdNdNCzaycn0=;
 b=mjNWpv7RlorVU+alD+DGlCi/7iOosVd4qx30Y8yI+SYsjabpq2oulHO2Og30/9IXroGiNFyyx
 1N0U3OgvxwfBAzBhmF032rC0IuvIVRzgi7aXHPxWljH7uD2yn/YyAIL
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Six variables in keyboard.c are written under kbd_event_lock and read either
without it or from a different handler, with plain accesses throughout:
shift_state, shift_down[], npadch_value, dead_key_next, accent_table_size,
and the in-place rebuild in do_compute_shiftstate().

vt_get_shift_state() is the one reader that deliberately takes no lock, so
the relation between shift_down[] and the shift_state summary word is
currently unspecified. The remaining pairs are lock-ordered today and those
patches only state the order in the code.

One patch fixes a real mistake rather than documenting an existing order:
vt_do_kdskbdiacr() sets accent_table_size before the loop that converts the
entries, so the size briefly covers entries that have not been written yet.
That store now follows the loop, in both ioctl paths.

Found with MBCheck, a static herd7-based memory consistency checker.
Compile-tested on arm64 with W=1, no new warnings.

---
Jaidev Shastri (6):
      vt: keyboard: publish shift_state with release semantics
      vt: keyboard: publish npadch_value with release semantics
      vt: keyboard: publish dead_key_next with release semantics
      vt: keyboard: publish accent_table_size with release semantics
      vt: keyboard: recompute the shift state into locals before publishing it
      vt: keyboard: publish the shift_down[] counters with release semantics

 drivers/tty/vt/keyboard.c | 72 ++++++++++++++++++++++++++++++++---------------
 1 file changed, 50 insertions(+), 22 deletions(-)
---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-keyboard-7f493253537e

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

