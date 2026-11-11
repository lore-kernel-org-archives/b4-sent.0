From: Nordschamane <nordschamane1@proton.me>
Date: Wed, 11 Nov 2026 17:25:48 +0800
Subject: [PATCH RFC v2] ALSA: pci: add analog support for ESI MAYA44e
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-codex-alsa-maya44e-v2-1-c5f94d722b54@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32QzW7DIBCEX8XiXFr+DLZPlSr1AXqtclhgiZFiS
 DG1EkV59xK35+5tVprZb/ZGViwRVzJ1N1Jwi2vMqQnx1BE3Qzoijb5pIpjQvA112eOFwmkFusA
 VlEIqnOKGD8awYEkznguGeNlDP8nH+xs5tKWFFaktkNz8yMslHmN6CbnQhJf6sM1xrblcd5SN7
 +b/rm6ccuqDZhCUkjjK13PJNafnBcnh/otR8Ou7Vap/LDuDy8sS69ShG0XvpVGM92NQVlkvrdG
 KWew988IqrRVnem8E1c3tE1MHSoq+x8F6LgJzbgDJjECA0cA4aPAGWoARDeH+A81U9y1dAQAA
X-Change-ID: 20261111-codex-alsa-maya44e-2c41718770fb
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-kernel@vger.kernel.org, linux-sound@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794389158; l=59679;
 i=nordschamane1@proton.me; s=maya44e-20261111; h=from:subject:message-id;
 bh=bFRoXLjowg7AGhQWZUIRHmycuWYFYMUA685mvMQkZjw=;
 b=V6udG+FpgdAR68jOCqVOBrsocJTMLuWFpll/tn1sPHZDOFz8I7NATX2QCywZjovKklXTRBKWw
 0KBMTuOHxrnDwbgHZE81dZEbHlPpq8eZu+tYCLH864D4mES5hXgwj9p
X-Developer-Key: i=nordschamane1@proton.me; a=ed25519;
 pk=DElwTnUfIzIJIRAscDi0+onWjXgpAyci+ZuDPLv2veQ=
X-Endpoint-Received: by B4 Relay for nordschamane1@proton.me/maya44e-20261111 with auth_id=1488
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add four-channel analog playback and capture for the ESI MAYA44e PCIe
card (19fe:7000, subsystem 0e51:0001). Playback and capture share the
sample clock and can use independent period sizes. Expose analog source,
gain, direct monitoring, DAC and crossmix controls.

The ES7010L register sequence comes from observed PCI transactions and
analysis of the ESI Windows driver. The existing ALSA PCI MAYA44 driver
was a reference for the WM8776 command format.

OpenAI Codex assisted with PCI trace analysis, driver implementation,
test tooling and the changelog. The requests covered analog playback,
capture, mixer controls and suspend/resume. For v2, Sashiko flagged
potential issues. Codex checked the report against the driver and ALSA
core and prepared the changes below.

Signed-off-by: Nordschamane <nordschamane1@proton.me>
---
Prerequisite: Joonho Lee's ALSA PCM reset callback under the stream
lock, v25 03/16. The diff matches the v23 version used for validation
(the hunk line numbers changed). Apply this patch before the driver:
https://lore.kernel.org/r/20261111025655.63951-4-mynameisjune111@gmail.com

Changes in v2:
- Pin the managed playback buffer while processing an ACK.
- Rebase playback pointers in the ALSA reset callback and advertise
  the shared sample clock when negotiating duplex rates.
- Stop all four DMA slots and disable phantom power on failed resume
  when the card is accessible in PCI D0. Disconnect the failed card so
  control operations waiting for D0 can return.
- Mute the analog monitor per channel at minimum capture volume and
  restore the saved PGA gain across codec reset.

Testing:
- Both patches apply to the ALSA for-next base listed below.
- Linux 7.0 x86-64 built with W=1 and CONFIG_PM_SLEEP enabled, with a
  context adjustment to the prerequisite for Linux 7.0.
- Host fixtures passed for RESET/prepare, DMA shutdown on failed
  resume, and per-channel analog monitor mute.
- An earlier v2 build passed four-channel playback, capture with
  undriven inputs, and duplex on a physical MAYA44e. The installed
  alpha.2 driver separately resumed from S3 with audible playback.
  The final v2 still needs hardware testing.

Link to v1:
https://lore.kernel.org/r/20261111-codex-alsa-maya44e-v1-1-df60af443e93@proton.me
---
 sound/pci/Kconfig   |   10 +
 sound/pci/Makefile  |    2 +
 sound/pci/maya44e.c | 1808 +++++++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 1820 insertions(+)

diff --git a/sound/pci/Kconfig b/sound/pci/Kconfig
index 6366f72..cb69fb9 100644
--- a/sound/pci/Kconfig
+++ b/sound/pci/Kconfig
@@ -746,6 +746,16 @@ config SND_MAESTRO3_INPUT
 	  If you say N the buttons will directly control the master volume.
 	  It is recommended to say Y.
 
+config SND_MAYA44E
+	tristate "ESI MAYA44e"
+	select SND_PCM
+	help
+	  Enable four-channel analog playback and capture on the ESI MAYA44e
+	  PCIe audio interface.
+
+	  To compile this driver as a module, choose M here. The module
+	  will be called snd-maya44e.
+
 config SND_MIXART
 	tristate "Digigram miXart"
 	select FW_LOADER
diff --git a/sound/pci/Makefile b/sound/pci/Makefile
index 9d5e8e1..aea2fef 100644
--- a/sound/pci/Makefile
+++ b/sound/pci/Makefile
@@ -22,6 +22,7 @@ snd-fm801-y := fm801.o
 snd-intel8x0-y := intel8x0.o
 snd-intel8x0m-y := intel8x0m.o
 snd-maestro3-y := maestro3.o
+snd-maya44e-y := maya44e.o
 snd-rme32-y := rme32.o
 snd-rme96-y := rme96.o
 snd-sis7019-y := sis7019.o
@@ -48,6 +49,7 @@ obj-$(CONFIG_SND_FM801) += snd-fm801.o
 obj-$(CONFIG_SND_INTEL8X0) += snd-intel8x0.o
 obj-$(CONFIG_SND_INTEL8X0M) += snd-intel8x0m.o
 obj-$(CONFIG_SND_MAESTRO3) += snd-maestro3.o
+obj-$(CONFIG_SND_MAYA44E) += snd-maya44e.o
 obj-$(CONFIG_SND_RME32) += snd-rme32.o
 obj-$(CONFIG_SND_RME96) += snd-rme96.o
 obj-$(CONFIG_SND_SIS7019) += snd-sis7019.o
diff --git a/sound/pci/maya44e.c b/sound/pci/maya44e.c
new file mode 100644
index 0000000..961dbde
--- /dev/null
+++ b/sound/pci/maya44e.c
@@ -0,0 +1,1808 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * ESI MAYA44e PCIe analog audio driver
+ *
+ * The controller has one DMA engine per stereo pair and direction.
+ * ALSA exposes four interleaved channels with a shared sample clock.
+ * Register behavior was reconstructed from observed transactions and
+ * analysis of the vendor Windows driver.
+ */
+#include <linux/delay.h>
+#include <linux/dma-mapping.h>
+#include <linux/interrupt.h>
+#include <linux/io.h>
+#include <linux/jiffies.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/pci.h>
+#include <linux/pm.h>
+#include <linux/slab.h>
+#include <linux/unaligned.h>
+#include <linux/workqueue.h>
+#include <sound/control.h>
+#include <sound/core.h>
+#include <sound/pcm.h>
+#include <sound/pcm_params.h>
+#include <sound/tlv.h>
+
+#define MAYA_MIN_PERIOD 128
+#define MAYA_DEFAULT_PERIOD 256
+#define MAYA_MAX_PERIOD 1024
+#define MAYA_MAX_FRAMES (MAYA_MAX_PERIOD * 2)
+#define MAYA_PAIR_BYTES_MAX (MAYA_MAX_FRAMES * 8)
+#define MAYA_PCM_BYTES_MAX (MAYA_MAX_FRAMES * 16)
+/* Preserve the original driver's full descriptor/service allocation span. */
+#define MAYA_DESC_BYTES 0x10100
+#define MAYA_POLL_LIMIT 100
+
+static const unsigned int maya_period_sizes[] = {128, 256, 512, 1024};
+static const struct snd_pcm_hw_constraint_list maya_period_constraints = {
+	.count = ARRAY_SIZE(maya_period_sizes),
+	.list = maya_period_sizes,
+};
+
+static bool maya_valid_period(snd_pcm_uframes_t period)
+{
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(maya_period_sizes); ++i)
+		if (maya_period_sizes[i] == period)
+			return true;
+	return false;
+}
+
+struct maya_rate_config {
+	unsigned int rate;
+	u16 word;
+	u8 nibble, gpio;
+};
+
+/* Recovered from Windows 0x14610. No 12/64/176.4/192 kHz branch exists there. */
+static const struct maya_rate_config maya_rates[] = {
+	{8000,  0x0531,  9, 0},
+	{11025, 0x4331,  5, 0},
+	{16000, 0x0231,  7, 0},
+	{22050, 0x4131,  4, 0},
+	{24000, 0x0131,  6, 0},
+	{32000, 0x0a31,  3, 0},
+	{44100, 0x4031,  0, 0},
+	{48000, 0x0031,  2, 0},
+	{88200, 0x4831, 10, 5},
+	{96000, 0x0831, 10, 5},
+};
+
+static const struct maya_rate_config *maya_find_rate(unsigned int rate)
+{
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(maya_rates); ++i)
+		if (maya_rates[i].rate == rate)
+			return &maya_rates[i];
+	return NULL;
+}
+
+static unsigned int maya_sample_bytes(snd_pcm_format_t format)
+{
+	switch (format) {
+	case SNDRV_PCM_FORMAT_S16_LE:
+		return 2;
+	case SNDRV_PCM_FORMAT_S24_3LE:
+		return 3;
+	case SNDRV_PCM_FORMAT_S24_LE:
+	case SNDRV_PCM_FORMAT_S32_LE:
+		return 4;
+	default:
+		return 0;
+	}
+}
+
+/* The controller always uses left-aligned 24-bit samples in LE32 words.
+ * S24_LE instead stores its 24 significant bits in the low three bytes.
+ * Unsigned shifts avoid signed overflow; widening adds zeros, not precision.
+ * S32_LE retains the established DMA path; only its top 24 bits reach I2S.
+ */
+static inline u32 maya_unpack_sample(const u8 *source, snd_pcm_format_t format)
+{
+	switch (format) {
+	case SNDRV_PCM_FORMAT_S16_LE:
+		return (u32)get_unaligned_le16(source) << 16;
+	case SNDRV_PCM_FORMAT_S24_3LE:
+		return get_unaligned_le24(source) << 8;
+	case SNDRV_PCM_FORMAT_S24_LE:
+		return get_unaligned_le32(source) << 8;
+	case SNDRV_PCM_FORMAT_S32_LE:
+		return get_unaligned_le32(source);
+	default:
+		return 0;
+	}
+}
+
+/* Narrowing discards low bits without dither. Applications can dither before
+ * submitting playback or request 24-bit capture and dither in userspace.
+ */
+static inline void maya_pack_sample(u8 *target, u32 sample, snd_pcm_format_t format)
+{
+	switch (format) {
+	case SNDRV_PCM_FORMAT_S16_LE:
+		put_unaligned_le16(sample >> 16, target);
+		break;
+	case SNDRV_PCM_FORMAT_S24_3LE:
+		put_unaligned_le24(sample >> 8, target);
+		break;
+	case SNDRV_PCM_FORMAT_S24_LE:
+		/* Sign-extend the nominal 24-bit value into its 32-bit container. */
+		put_unaligned_le32((s32)sample >> 8, target);
+		break;
+	case SNDRV_PCM_FORMAT_S32_LE:
+		put_unaligned_le32(sample, target);
+		break;
+	default:
+		break;
+	}
+}
+
+struct maya_desc {
+	__le32 address, address_high, bytes, reserved;
+};
+
+struct maya_capture {
+	struct snd_pcm_substream *substream;
+	void *ring[2];
+	dma_addr_t dma[2];
+	bool running;
+	unsigned int period, frames, position;
+};
+
+struct maya {
+	struct pci_dev *pci;
+	struct snd_pcm *pcm;
+	struct snd_pcm_substream *substream;
+	struct maya_capture capture;
+	unsigned int reserved_rate[2];
+	u8 input_volume[2][2], input_gain[2], input_source[2];
+	u8 input_pga_volume[2][2];
+	bool input_enabled[2], monitor[2];
+	struct work_struct fault_work;
+	void __iomem *io;
+	/* Protects IRQ/DMA state; may be nested inside codec_lock. */
+	spinlock_t lock;
+	/* Serializes codec/control operations; never taken under lock. */
+	struct mutex codec_lock;
+	void *ring[2], *desc_allocation, *table;
+	dma_addr_t ring_dma[2], desc_dma, table_dma;
+	bool enabled, regions, irq_requested, running, fault, removing, suspended;
+	unsigned int suspend_rate;
+	unsigned int rate, period_frames, buffer_frames;
+	snd_pcm_uframes_t last_appl; /* Protected by the PCM stream lock. */
+	u8 dac[2][2], mix[2];
+	bool mix_enabled[2], dac_enabled[2];
+	unsigned long irq_window;
+	u32 irq_window_handled, irq_unexpected;
+};
+
+static u8 mr8(struct maya *m, unsigned int reg)
+{
+	udelay(1);
+	return readb(m->io + reg);
+}
+
+static u32 mr32(struct maya *m, unsigned int reg)
+{
+	udelay(1);
+	return readl(m->io + reg);
+}
+
+static void mw8(struct maya *m, unsigned int reg, u8 value)
+{
+	writeb(value, m->io + reg);
+	udelay(1);
+}
+
+static void mw16(struct maya *m, unsigned int reg, u16 value)
+{
+	writew(value, m->io + reg);
+	udelay(1);
+}
+
+static void mw32(struct maya *m, unsigned int reg, u32 value)
+{
+	writel(value, m->io + reg);
+	udelay(1);
+}
+
+/* Caller holds m->lock, or probe/free has exclusive ownership. */
+static void maya_quiesce(struct maya *m, bool mmio_active)
+{
+	unsigned int slot;
+
+	m->running = false;
+	m->capture.running = false;
+	pci_intx(m->pci, 0);
+	pci_clear_master(m->pci);
+	if (m->io && mmio_active) {
+		for (slot = 0; slot < 4; ++slot) {
+			mw8(m, 0x192 + slot * 4, 2);
+			mw8(m, 0x80 + slot * 0x20, 0);
+		}
+		mw8(m, 0x481, mr8(m, 0x481) & ~BIT(6));
+		/* Flush the posted stop and GPIO writes before leaving D0. */
+		mr8(m, 0x481);
+	}
+}
+
+static void maya_fatal(struct maya *m)
+{
+	bool notify = !m->fault && !m->removing && !m->suspended && m->pcm;
+
+	m->fault = true;
+	maya_quiesce(m, !m->suspended);
+	/* Fatal callers can hold stream/device locks. Notify ALSA elsewhere. */
+	if (notify)
+		schedule_work(&m->fault_work);
+}
+
+/* Each close clears its pointer under lock, then flushes this work before
+ * its runtime can disappear. Flushing rather than cancelling also preserves
+ * notification of a still-open peer. No driver lock is held while calling ALSA.
+ */
+static void maya_fault_work(struct work_struct *work)
+{
+	struct maya *m = container_of(work, struct maya, fault_work);
+	struct snd_pcm_substream *playback, *capture;
+	unsigned long flags;
+
+	spin_lock_irqsave(&m->lock, flags);
+	playback = m->substream;
+	capture = m->capture.substream;
+	spin_unlock_irqrestore(&m->lock, flags);
+	if (playback)
+		snd_pcm_stop_xrun(playback);
+	if (capture)
+		snd_pcm_stop_xrun(capture);
+}
+
+/* DMA must already be stopped, or probe must have exclusive ownership with
+ * bus mastering disabled. Allocation sizes remain constant; only the active
+ * ring changes. Both stereo pairs always use the same period and ring size.
+ */
+static void maya_configure_buffer(struct maya *m, unsigned int period)
+{
+	unsigned int pair, half;
+
+	m->period_frames = period;
+	m->buffer_frames = period * 2;
+	for (pair = 0; pair < 2; ++pair) {
+		struct maya_desc *descriptors = m->table + 0x200 + pair * 0x100;
+
+		for (half = 0; half < 2; ++half) {
+			descriptors[half].address =
+				cpu_to_le32(lower_32_bits(m->ring_dma[pair] + half * period * 8));
+			descriptors[half].address_high = 0;
+			descriptors[half].bytes = cpu_to_le32(period * 8);
+			descriptors[half].reserved = 0;
+		}
+	}
+	dma_wmb();
+}
+
+/* This is the original reset/rearm sequence, with an explicit timeout error.
+ * It never starts DMA. A failed reset cuts off bus mastering before any free.
+ */
+static int maya_rearm(struct maya *m, unsigned int pair)
+{
+	unsigned int b = 0xc0 + pair * 0x20;
+	unsigned int irq = 0x198 + pair * 4;
+	unsigned int i;
+
+	mw32(m, b, 0xff000000);
+	mw8(m, irq + 2, 2);
+	mw8(m, b, 1);
+	for (i = 0; i < MAYA_POLL_LIMIT; ++i) {
+		if (mr32(m, b) & 1)
+			break;
+		/* Reset callers may hold m->lock, so this wait must not sleep. */
+		udelay(10);
+	}
+	if (i == MAYA_POLL_LIMIT) {
+		maya_fatal(m);
+		return -ETIMEDOUT;
+	}
+	mw8(m, b, 0);
+	mw32(m, b + 0x18, lower_32_bits(m->table_dma + 0x200 + pair * 0x100));
+	mw32(m, b + 0x1c, 0);
+	mw16(m, b + 0x10, 0xbf);
+	mw16(m, b + 0x0e, 4);
+	mw8(m, b + 0x0c, 1);
+	mw32(m, b + 8, m->buffer_frames * 8);
+	mw16(m, irq, m->period_frames);
+	return 0;
+}
+
+static void maya_start_pair(struct maya *m, unsigned int pair)
+{
+	unsigned int b = 0xc0 + pair * 0x20;
+
+	mw8(m, b + 3, 0xff);
+	mw8(m, 0x19a + pair * 4, pair ? 3 : 7);
+	if (!(mr32(m, b) & 2))
+		mw8(m, b, 2);
+}
+
+static int maya_stop(struct maya *m)
+{
+	unsigned int pair;
+
+	m->running = false;
+	if (m->fault)
+		return -EIO;
+	/* Preserve a running capture peer: reset is deferred to prepare. */
+	for (pair = 0; pair < 2; ++pair) {
+		mw8(m, 0x19a + pair * 4, 2);
+		mw8(m, 0xc0 + pair * 0x20, 0);
+	}
+	return 0;
+}
+
+/* The codec command interface may sleep and is serialized by codec_lock. */
+static int maya_codec_ready(struct maya *m)
+{
+	unsigned int i;
+
+	for (i = 0; i < 200; ++i) {
+		if (!(mr32(m, 0x4c4) & 0x80))
+			return 0;
+		usleep_range(100, 200);
+	}
+
+	return -ETIMEDOUT;
+}
+
+static int maya_codec_write(struct maya *m, unsigned int codec,
+			    unsigned int reg, u16 value)
+{
+	unsigned int command = (reg << 1) | ((value >> 8) & 1);
+	int err = maya_codec_ready(m);
+
+	if (err)
+		return err;
+	udelay(1);
+	mw8(m, 0x4c0, codec ? 0x36 : 0x34);
+	udelay(1);
+	mw8(m, 0x4c1, command);
+	udelay(1);
+	mw8(m, 0x4c2, command >> 8);
+	udelay(1);
+	mw8(m, 0x4c3, 1);
+	mw32(m, 0x4c4, 0xe0000010);
+	mw8(m, 0x4d0, value);
+	mw8(m, 0x4c4, 0x90);
+	/* Unlike the original, propagate a timeout from the last command too. */
+	return maya_codec_ready(m);
+}
+
+static int maya_codec_init(struct maya *m)
+{
+	static const struct { u8 reg; u16 value; } init[] = {
+		{0, 0x1f9}, {1, 0x1f9}, {2, 0x100},
+		{3, 0x100}, {4, 0x100}, {5, 0x100},
+		{6, 0}, {7, 0x95}, {8, 0}, {9, 0}, {10, 0x22},
+		{11, 0x22}, {12, 0x22}, {13, 0}, {14, 0x1cf},
+		{15, 0x1cf}, {16, 0x7a}, {17, 0}, {18, 0x32},
+		{19, 0}, {20, 0xbc}, {21, 2}, {22, 1},
+	};
+	unsigned int pass, codec, i;
+	int err;
+
+	mw8(m, 0x480, 0xff);
+	mw8(m, 0x481, 0xaa);
+	usleep_range(1000, 1500);
+	for (pass = 0; pass < 5; ++pass) {
+		for (codec = 0; codec < 2; ++codec) {
+			for (i = 0; i < ARRAY_SIZE(init); ++i) {
+				err = maya_codec_write(m, codec, init[i].reg,
+						       init[i].value);
+				if (err)
+					return err;
+				udelay(2);
+			}
+		}
+		usleep_range(1000, 1500);
+	}
+	mw8(m, 0x481, 0x2a);
+	for (codec = 0; codec < 2; ++codec) {
+		/* R5 is master: set it before restoring independently cached L/R. */
+		err = maya_codec_write(m, codec, 5, 0x1c3);
+		if (err)
+			return err;
+		for (i = 0; i < 2; ++i) {
+			err = maya_codec_write(m, codec, 3 + i, 0x100 | m->dac[codec][i]);
+			if (err)
+				return err;
+		}
+		err = maya_codec_write(m, codec, 2, 0x100);
+		if (err)
+			return err;
+	}
+	return 0;
+}
+
+/* Caller holds codec_lock then lock, or probe has exclusive ownership.
+ * This only touches clock-selection registers, never mixer levels/routes or
+ * DMA start bits. Keep the Windows access order, widths and bit-preserving masks.
+ */
+static int maya_set_rate(struct maya *m, unsigned int rate)
+{
+	const struct maya_rate_config *config = maya_find_rate(rate);
+	u32 value;
+	u8 old481;
+	unsigned int i;
+
+	if (!config)
+		return -EINVAL;
+	if (m->fault || m->removing)
+		return -EIO;
+	if (m->rate == rate)
+		return 0;
+	if (m->running || m->capture.running)
+		return -EBUSY;
+	old481 = mr8(m, 0x481);
+	for (i = 0; i < 4; ++i)
+		mw16(m, 0x92 + i * 0x20, config->word);
+	udelay(1);
+	mw8(m, 0x481, (old481 & 0xfa) | config->gpio);
+	value = mr8(m, 0x18a);
+	if (value & 15)
+		mw8(m, 0x18a, value & 0xf0);
+	value = mr32(m, 0x1a0);
+	mw32(m, 0x1a0, (value & 0xffff0fff) | (config->nibble << 12));
+	WRITE_ONCE(m->rate, rate);
+	return 0;
+}
+
+static int maya_controller_init(struct maya *m)
+{
+	u32 value;
+	unsigned int i;
+	int err;
+
+	value = mr32(m, 8) & ~BIT(31);
+	mw32(m, 8, value);
+	msleep(200);
+	mw32(m, 8, value | BIT(31));
+	msleep(200);
+	mw32(m, 0x4e4, 0x38000);
+	value = mr32(m, 0x4e0);
+	for (i = 0; i < 20; ++i) {
+		mw32(m, 0x4e0, value | BIT(22));
+		mw32(m, 0x4e0, value & ~BIT(22));
+	}
+	mw8(m, 0x188, mr8(m, 0x188) & 0xf8);
+	mw8(m, 0x189, mr8(m, 0x189) & 0x98);
+	/* Disable digital output and select the external receive path. */
+	mw32(m, 0x1a0, 0);
+	mw32(m, 0x1b0, BIT(31));
+	/* Preserve the Windows initial 44.1 kHz-family setting during codec init. */
+	for (i = 0; i < 4; ++i)
+		mw16(m, 0x92 + i * 0x20, 0x4031);
+	err = maya_codec_init(m);
+	if (err)
+		return err;
+	/* Use 48 kHz until a PCM stream selects its clock. */
+	err = maya_set_rate(m, 48000);
+	if (err)
+		return err;
+	mw32(m, 0x70, lower_32_bits(m->table_dma + 0xa00));
+	err = maya_rearm(m, 0);
+	return err ? err : maya_rearm(m, 1);
+}
+
+/* Input DMA has the same two-descriptor layout as output, but format 0x77.
+ * Only the input engines are reset here; active playback is never touched.
+ */
+static int maya_capture_rearm(struct maya *m, unsigned int pair)
+{
+	unsigned int b = 0x80 + pair * 0x20, ir = 0x190 + pair * 4, i;
+
+	mw32(m, b, 0xff000000);
+	mw8(m, ir + 2, 2);
+	mw8(m, b, 1);
+	for (i = 0; i < MAYA_POLL_LIMIT; ++i) {
+		if (mr32(m, b) & 1)
+			break;
+		/* Reset callers may hold m->lock, so this wait must not sleep. */
+		udelay(10);
+	}
+	if (i == MAYA_POLL_LIMIT) {
+		maya_fatal(m);
+		return -ETIMEDOUT;
+	}
+	mw8(m, b, 0);
+	mw32(m, b + 0x18, lower_32_bits(m->table_dma + pair * 0x100));
+	mw32(m, b + 0x1c, 0);
+	mw16(m, b + 0x10, 0x77);
+	mw16(m, b + 0x0e, 4);
+	mw8(m, b + 0x0c, 1);
+	mw32(m, b + 8, m->capture.frames * 8);
+	mw16(m, ir, m->capture.period);
+	return 0;
+}
+
+static int maya_capture_stop(struct maya *m)
+{
+	unsigned int pair;
+
+	m->capture.running = false;
+	if (m->fault)
+		return -EIO;
+	/* Stop promptly. Full reset belongs to prepare, not the IRQ-disabled
+	 * STOP path: resetting both engines here can starve the playback peer.
+	 */
+	for (pair = 0; pair < 2; ++pair) {
+		mw8(m, 0x192 + pair * 4, 2);
+		mw8(m, 0x80 + pair * 0x20, 0);
+	}
+	return 0;
+}
+
+/* The 3/4 engine starts first. At a 1/2 boundary both completed stereo
+ * halves can be combined. Expose only the half copied to ALSA, never the
+ * still-being-written half. Coarse period pointers are intentional.
+ */
+static void maya_capture_period(struct maya *m)
+{
+	struct maya_capture *c = &m->capture;
+	struct snd_pcm_runtime *runtime = c->substream->runtime;
+	unsigned int sample_bytes = maya_sample_bytes(runtime->format);
+	u8 *dst = runtime->dma_area;
+	__le32 *left = c->ring[0], *right = c->ring[1];
+	unsigned int pos = (mr32(m, 0x84) >> 3) % c->frames;
+	unsigned int start = (pos / c->period ^ 1) * c->period, i;
+	bool pass[4];
+
+	/* R21 mutes the analogue PGA input; ADC noise/settling can remain.
+	 * Guarantee exact digital silence for Capture Switch off and -infinity.
+	 * Snapshot once per completed period, preserving independent L/R.
+	 */
+	for (i = 0; i < 4; ++i)
+		pass[i] = READ_ONCE(m->input_enabled[i / 2]) &&
+			READ_ONCE(m->input_volume[i / 2][i % 2]) != 0;
+
+	dma_rmb();
+	for (i = start; i < start + c->period; ++i) {
+		u8 *frame = dst + i * sample_bytes * 4;
+
+		maya_pack_sample(frame, pass[0] ? le32_to_cpu(left[i * 2]) : 0,
+				 runtime->format);
+		maya_pack_sample(frame + sample_bytes,
+				 pass[1] ? le32_to_cpu(left[i * 2 + 1]) : 0,
+				 runtime->format);
+		maya_pack_sample(frame + sample_bytes * 2,
+				 pass[2] ? le32_to_cpu(right[i * 2]) : 0,
+				 runtime->format);
+		maya_pack_sample(frame + sample_bytes * 3,
+				 pass[3] ? le32_to_cpu(right[i * 2 + 1]) : 0,
+				 runtime->format);
+	}
+	c->position = (start + c->period) % c->frames;
+}
+
+static irqreturn_t maya_irq(int irq, void *opaque)
+{
+	struct maya *m = opaque;
+	struct snd_pcm_substream *substream = NULL, *capture = NULL;
+	unsigned long flags;
+	u32 summary, extra;
+	u8 status;
+	unsigned int pair;
+	bool tick = false, capture_tick = false, failed = false;
+
+	spin_lock_irqsave(&m->lock, flags);
+
+	if (m->fault || m->removing || m->suspended) {
+		spin_unlock_irqrestore(&m->lock, flags);
+		return IRQ_NONE;
+	}
+	summary = mr32(m, 0x4b0);
+
+	if (!summary) {
+		spin_unlock_irqrestore(&m->lock, flags);
+		return IRQ_NONE;
+	}
+
+	if (time_after(jiffies, m->irq_window + HZ)) {
+		m->irq_window = jiffies;
+		m->irq_window_handled = 0;
+	}
+	/* Count only this device's asserted sources, not shared IRQ_NONE calls. */
+	if (++m->irq_window_handled > 8192) {
+		failed = true;
+		goto fatal;
+	}
+	for (pair = 0; pair < 4; ++pair) {
+		unsigned int b = 0x80 + pair * 0x20;
+		unsigned int ir = 0x190 + pair * 4;
+		bool pending;
+
+		if (!(summary & BIT(pair)))
+			continue;
+		status = mr8(m, b + 3);
+		extra = mr32(m, ir);
+		pending = (extra & 0x20000) || (status & 4);
+		if (extra & 0x20000)
+			mw8(m, ir + 2, extra >> 16);
+		if (status & 4)
+			mw8(m, b + 3, status);
+		if (pair == 2 && pending)
+			tick = true;
+		if (pair == 0 && pending)
+			capture_tick = true;
+	}
+	if (summary & ~0x0f) {
+		m->irq_unexpected++;
+		if (m->irq_unexpected >= 16) {
+			failed = true;
+			goto fatal;
+		}
+	}
+	if (capture_tick && m->capture.running && m->capture.substream) {
+		maya_capture_period(m);
+		capture = m->capture.substream;
+	}
+	if (tick && m->running)
+		substream = m->substream;
+	goto unlock;
+fatal:
+	maya_fatal(m);
+unlock:
+	spin_unlock_irqrestore(&m->lock, flags);
+	if (failed) {
+		dev_err_ratelimited(&m->pci->dev,
+				    "interrupt fault: summary=%#x; bus mastering and INTx disabled\n",
+				    summary);
+	} else {
+		if (substream)
+			snd_pcm_period_elapsed(substream);
+		if (capture)
+			snd_pcm_period_elapsed(capture);
+	}
+	return IRQ_HANDLED;
+}
+
+static const struct snd_pcm_hardware maya_pcm_hardware = {
+	.info = SNDRV_PCM_INFO_INTERLEAVED | SNDRV_PCM_INFO_BLOCK_TRANSFER |
+		SNDRV_PCM_INFO_MMAP | SNDRV_PCM_INFO_MMAP_VALID |
+		SNDRV_PCM_INFO_SYNC_APPLPTR | SNDRV_PCM_INFO_NO_REWINDS |
+		SNDRV_PCM_INFO_JOINT_DUPLEX,
+	.formats = SNDRV_PCM_FMTBIT_S16_LE | SNDRV_PCM_FMTBIT_S24_3LE |
+		SNDRV_PCM_FMTBIT_S24_LE | SNDRV_PCM_FMTBIT_S32_LE,
+	.rates = SNDRV_PCM_RATE_8000_48000 | SNDRV_PCM_RATE_24000 |
+		SNDRV_PCM_RATE_88200 | SNDRV_PCM_RATE_96000,
+	.rate_min = 8000, .rate_max = 96000,
+	.channels_min = 4, .channels_max = 4,
+	.buffer_bytes_max = MAYA_PCM_BYTES_MAX,
+	.period_bytes_min = MAYA_MIN_PERIOD * 8,
+	.period_bytes_max = MAYA_MAX_PERIOD * 16,
+	.periods_min = 2, .periods_max = 2,
+};
+
+/* Full duplex shares one clock, but each direction may use its own period.
+ * Reserve at hw_params, not just while running, to protect prepared peers.
+ */
+static int maya_hw_params(struct snd_pcm_substream *s, struct snd_pcm_hw_params *p)
+{
+	struct maya *m = snd_pcm_substream_chip(s);
+	unsigned int direction = s->stream;
+	int err = 0;
+
+	mutex_lock(&m->codec_lock);
+	if (m->reserved_rate[1 - direction] &&
+	    m->reserved_rate[1 - direction] != params_rate(p))
+		err = -EBUSY;
+	else
+		m->reserved_rate[direction] = params_rate(p);
+	mutex_unlock(&m->codec_lock);
+	return err;
+}
+
+static int maya_hw_free(struct snd_pcm_substream *s)
+{
+	struct maya *m = snd_pcm_substream_chip(s);
+
+	mutex_lock(&m->codec_lock);
+	m->reserved_rate[s->stream] = 0;
+	mutex_unlock(&m->codec_lock);
+	return 0;
+}
+
+static int maya_rate_rule(struct snd_pcm_hw_params *params,
+			  struct snd_pcm_hw_rule *rule)
+{
+	struct snd_pcm_substream *s = rule->private;
+	struct maya *m = snd_pcm_substream_chip(s);
+	struct snd_interval limit = { .integer = 1 };
+	unsigned int rate;
+
+	mutex_lock(&m->codec_lock);
+	rate = m->reserved_rate[1 - s->stream];
+	mutex_unlock(&m->codec_lock);
+	if (!rate)
+		return 0;
+
+	limit.min = rate;
+	limit.max = rate;
+	return snd_interval_refine(hw_param_interval(params, SNDRV_PCM_HW_PARAM_RATE),
+				   &limit);
+}
+
+static int maya_pcm_constraints(struct snd_pcm_substream *s)
+{
+	struct snd_pcm_runtime *r = s->runtime;
+	int err;
+
+	err = snd_pcm_hw_constraint_integer(r, SNDRV_PCM_HW_PARAM_PERIODS);
+	if (err < 0)
+		return err;
+	err = snd_pcm_hw_constraint_list(r, 0, SNDRV_PCM_HW_PARAM_PERIOD_SIZE,
+					 &maya_period_constraints);
+	if (err < 0)
+		return err;
+	/* S32_LE carries 24 significant MSBs. */
+	err = snd_pcm_hw_constraint_msbits(r, 0, 32, 24);
+	if (err < 0)
+		return err;
+	return snd_pcm_hw_rule_add(r, 0, SNDRV_PCM_HW_PARAM_RATE, maya_rate_rule,
+				   s, SNDRV_PCM_HW_PARAM_RATE, -1);
+}
+
+static int maya_open(struct snd_pcm_substream *s)
+{
+	struct maya *m = snd_pcm_substream_chip(s);
+	unsigned long flags;
+	int err;
+
+	if (READ_ONCE(m->fault) || READ_ONCE(m->removing) || READ_ONCE(m->suspended))
+		return -EIO;
+	s->runtime->hw = maya_pcm_hardware;
+	err = maya_pcm_constraints(s);
+	if (err < 0)
+		return err;
+	spin_lock_irqsave(&m->lock, flags);
+	m->substream = s;
+	spin_unlock_irqrestore(&m->lock, flags);
+	return 0;
+}
+
+static int maya_close(struct snd_pcm_substream *s)
+{
+	struct maya *m = snd_pcm_substream_chip(s);
+	unsigned long flags;
+
+	spin_lock_irqsave(&m->lock, flags);
+	if (m->running)
+		maya_stop(m);
+	m->substream = NULL;
+	spin_unlock_irqrestore(&m->lock, flags);
+	flush_work(&m->fault_work);
+	synchronize_irq(m->pci->irq);
+	return 0;
+}
+
+static int maya_pcm_reset(struct snd_pcm_substream *s)
+{
+	struct maya *m = snd_pcm_substream_chip(s);
+	int err;
+
+	/* ALSA rebases appl_ptr from this hw_ptr under the same stream lock. */
+	err = snd_pcm_lib_reset(s);
+	if (err < 0)
+		return err;
+	m->last_appl = s->runtime->status->hw_ptr;
+	return 0;
+}
+
+static int maya_prepare(struct snd_pcm_substream *s)
+{
+	struct maya *m = snd_pcm_substream_chip(s);
+	unsigned long flags;
+	int err;
+
+	if (!maya_sample_bytes(s->runtime->format) ||
+	    !maya_valid_period(s->runtime->period_size) ||
+	    s->runtime->buffer_size != s->runtime->period_size * 2 ||
+	    !maya_find_rate(s->runtime->rate))
+		return -EINVAL;
+	mutex_lock(&m->codec_lock);
+	spin_lock_irqsave(&m->lock, flags);
+	if (m->fault || m->removing || m->suspended)
+		err = -EIO;
+	else if (m->running)
+		err = -EBUSY;
+	else
+		err = maya_stop(m);
+	spin_unlock_irqrestore(&m->lock, flags);
+	if (!err) {
+		unsigned int pair, pass;
+
+		/* Reset the old layout first: a failed reset must not replace
+		 * descriptors or the cached geometry. Each reset releases IRQs.
+		 */
+		for (pass = 0; pass < 2 && !err; ++pass) {
+			if (pass) {
+				if (m->period_frames == s->runtime->period_size)
+					break;
+				maya_configure_buffer(m, s->runtime->period_size);
+			}
+			for (pair = 0; pair < 2; ++pair) {
+				spin_lock_irqsave(&m->lock, flags);
+				err = m->fault || m->removing || m->suspended ?
+					-EIO : maya_rearm(m, pair);
+				spin_unlock_irqrestore(&m->lock, flags);
+				if (err)
+					break;
+			}
+		}
+		if (!err) {
+			spin_lock_irqsave(&m->lock, flags);
+			err = maya_set_rate(m, s->runtime->rate);
+			spin_unlock_irqrestore(&m->lock, flags);
+		}
+	}
+	mutex_unlock(&m->codec_lock);
+	if (err)
+		return err;
+	/* A linked prepare can leave the playback buffer open to ack. */
+	snd_pcm_stream_lock_irqsave(s, flags);
+	memset(m->ring[0], 0, m->buffer_frames * 8);
+	memset(m->ring[1], 0, m->buffer_frames * 8);
+	memset(s->runtime->dma_area, 0,
+	       s->runtime->buffer_size * maya_sample_bytes(s->runtime->format) * 4);
+	dma_wmb();
+	snd_pcm_stream_unlock_irqrestore(s, flags);
+	return 0;
+}
+
+static int maya_trigger(struct snd_pcm_substream *s, int command)
+{
+	struct maya *m = snd_pcm_substream_chip(s);
+	unsigned long flags;
+	int err = 0;
+
+	spin_lock_irqsave(&m->lock, flags);
+	if (m->fault || m->removing || m->suspended) {
+		spin_unlock_irqrestore(&m->lock, flags);
+		return -EIO;
+	}
+	switch (command) {
+	case SNDRV_PCM_TRIGGER_START:
+		dma_wmb();
+		maya_start_pair(m, 1);
+		maya_start_pair(m, 0);
+		m->running = true;
+		break;
+	case SNDRV_PCM_TRIGGER_STOP:
+	case SNDRV_PCM_TRIGGER_SUSPEND:
+		err = maya_stop(m);
+		break;
+	default:
+		err = -EINVAL;
+	}
+	/* Flush posted PCI writes before returning to the PCM core. */
+	if (!err)
+		mr32(m, 0xc0);
+	spin_unlock_irqrestore(&m->lock, flags);
+	return err;
+}
+
+static int maya_sync_stop(struct snd_pcm_substream *s)
+{
+	struct maya *m = snd_pcm_substream_chip(s);
+
+	synchronize_irq(m->pci->irq);
+	return 0;
+}
+
+static snd_pcm_uframes_t maya_pointer(struct snd_pcm_substream *s)
+{
+	struct maya *m = snd_pcm_substream_chip(s);
+	unsigned long flags;
+	u32 position, frames;
+
+	spin_lock_irqsave(&m->lock, flags);
+	position = m->fault || m->removing || m->suspended ? 0 : mr32(m, 0xc4);
+	frames = m->buffer_frames;
+	spin_unlock_irqrestore(&m->lock, flags);
+	return (position >> 3) % frames;
+}
+
+/* ALSA calls ack after committing appl_ptr, under its stream lock. Explicit
+ * appl_ptr synchronization is mandatory because the mmap staging buffer is
+ * not the controller's pair-interleaved DMA layout. Rewinds are disabled.
+ */
+static int maya_ack(struct snd_pcm_substream *s)
+{
+	struct maya *m = snd_pcm_substream_chip(s);
+	struct snd_pcm_runtime *r = s->runtime;
+	__le32 *out12 = m->ring[0], *out34 = m->ring[1];
+	snd_pcm_uframes_t appl, frame;
+	snd_pcm_sframes_t count;
+	unsigned int sample_bytes;
+	int err = 0;
+
+	if (READ_ONCE(m->fault) || READ_ONCE(m->removing) || READ_ONCE(m->suspended))
+		return -EIO;
+	/* SYNC_PTR can call ack without pinning the managed PCM buffer. */
+	if (!atomic_inc_unless_negative(&r->buffer_accessing))
+		return -EBUSY;
+	if (!r->dma_area || !r->buffer_size || r->state == SNDRV_PCM_STATE_SETUP) {
+		err = -EBADFD;
+		goto out;
+	}
+	sample_bytes = maya_sample_bytes(r->format);
+	if (!sample_bytes) {
+		err = -EINVAL;
+		goto out;
+	}
+	appl = READ_ONCE(r->control->appl_ptr);
+	count = appl - m->last_appl;
+	if (count < 0)
+		count += r->boundary;
+	if (count < 0 || count > (snd_pcm_sframes_t)r->buffer_size) {
+		dev_err_ratelimited(&m->pci->dev,
+				    "invalid appl_ptr delta=%ld old=%lu new=%lu boundary=%lu\n",
+				    count, m->last_appl, appl, r->boundary);
+		err = -EINVAL;
+		goto out;
+	}
+	for (frame = 0; frame < (snd_pcm_uframes_t)count; ++frame) {
+		unsigned int slot = (m->last_appl + frame) % r->buffer_size;
+		const u8 *source = r->dma_area + slot * sample_bytes * 4;
+
+		out12[slot * 2] = cpu_to_le32(maya_unpack_sample(source, r->format));
+		out12[slot * 2 + 1] =
+			cpu_to_le32(maya_unpack_sample(source + sample_bytes, r->format));
+		out34[slot * 2] =
+			cpu_to_le32(maya_unpack_sample(source + sample_bytes * 2, r->format));
+		out34[slot * 2 + 1] =
+			cpu_to_le32(maya_unpack_sample(source + sample_bytes * 3, r->format));
+	}
+	dma_wmb();
+	m->last_appl = appl;
+out:
+	atomic_dec(&r->buffer_accessing);
+	return err;
+}
+
+static int maya_fill_silence(struct snd_pcm_substream *s, int channel,
+			     unsigned long position, unsigned long bytes)
+{
+	struct maya *m = snd_pcm_substream_chip(s);
+	unsigned int frame_bytes = maya_sample_bytes(s->runtime->format) * 4;
+	unsigned long ring_bytes = s->runtime->buffer_size * frame_bytes;
+	unsigned long dma_position, dma_bytes;
+
+	(void)channel; /* Only four-channel interleaved PCM is exposed. */
+	/* The ALSA core splits the request at the logical ring end. */
+	if (!frame_bytes || position % frame_bytes || bytes % frame_bytes ||
+	    position > ring_bytes ||
+	    bytes > ring_bytes - position)
+		return -EINVAL;
+	dma_position = position / frame_bytes * 8;
+	dma_bytes = bytes / frame_bytes * 8;
+	memset(s->runtime->dma_area + position, 0, bytes);
+	memset(m->ring[0] + dma_position, 0, dma_bytes);
+	memset(m->ring[1] + dma_position, 0, dma_bytes);
+	dma_wmb();
+
+	return 0;
+}
+
+static const struct snd_pcm_ops maya_pcm_ops = {
+	.open = maya_open,
+	.close = maya_close,
+	.ioctl = snd_pcm_lib_ioctl,
+	.hw_params = maya_hw_params,
+	.hw_free = maya_hw_free,
+	.prepare = maya_prepare,
+	.trigger = maya_trigger,
+	.sync_stop = maya_sync_stop,
+	.pointer = maya_pointer,
+	.ack = maya_ack,
+	.reset = maya_pcm_reset,
+	.fill_silence = maya_fill_silence,
+};
+
+static int maya_capture_open(struct snd_pcm_substream *s)
+{
+	struct maya *m = snd_pcm_substream_chip(s);
+	unsigned long flags;
+	int err;
+
+	if (READ_ONCE(m->fault) || READ_ONCE(m->removing) || READ_ONCE(m->suspended))
+		return -EIO;
+	s->runtime->hw = maya_pcm_hardware;
+	/* ADC datasheet rates start at 32 kHz; lower controller rates are not
+	 * yet validated for capture. Do not advertise unsupported ADC clocks.
+	 */
+	s->runtime->hw.rates = SNDRV_PCM_RATE_32000 | SNDRV_PCM_RATE_44100 |
+		SNDRV_PCM_RATE_48000 | SNDRV_PCM_RATE_88200 | SNDRV_PCM_RATE_96000;
+	s->runtime->hw.rate_min = 32000;
+	err = maya_pcm_constraints(s);
+	if (err < 0)
+		return err;
+	spin_lock_irqsave(&m->lock, flags);
+	m->capture.substream = s;
+	spin_unlock_irqrestore(&m->lock, flags);
+	return 0;
+}
+
+static int maya_capture_close(struct snd_pcm_substream *s)
+{
+	struct maya *m = snd_pcm_substream_chip(s);
+	unsigned long flags;
+
+	spin_lock_irqsave(&m->lock, flags);
+	if (m->capture.running)
+		maya_capture_stop(m);
+	m->capture.substream = NULL;
+	spin_unlock_irqrestore(&m->lock, flags);
+	flush_work(&m->fault_work);
+	synchronize_irq(m->pci->irq);
+	return 0;
+}
+
+static int maya_capture_prepare(struct snd_pcm_substream *s)
+{
+	struct maya *m = snd_pcm_substream_chip(s);
+	struct maya_capture *c = &m->capture;
+	unsigned long flags;
+	unsigned int pair, half, period = s->runtime->period_size;
+	int err = 0;
+
+	if (!maya_sample_bytes(s->runtime->format) ||
+	    !maya_valid_period(period) || s->runtime->buffer_size != period * 2 ||
+	    s->runtime->rate < 32000 || !maya_find_rate(s->runtime->rate))
+		return -EINVAL;
+	mutex_lock(&m->codec_lock);
+	spin_lock_irqsave(&m->lock, flags);
+	if (m->fault || m->removing || m->suspended)
+		err = -EIO;
+	else if (c->running)
+		err = -EBUSY;
+	else
+		err = maya_set_rate(m, s->runtime->rate);
+	if (!err)
+		err = maya_capture_stop(m);
+	spin_unlock_irqrestore(&m->lock, flags);
+	if (!err) {
+		c->period = period;
+		c->frames = period * 2;
+		c->position = 0;
+		for (pair = 0; pair < 2; ++pair) {
+			struct maya_desc *descriptors = m->table + pair * 0x100;
+
+			for (half = 0; half < 2; ++half) {
+				descriptors[half].address =
+					cpu_to_le32(lower_32_bits(c->dma[pair] +
+								  half * period * 8));
+				descriptors[half].address_high = 0;
+				descriptors[half].bytes = cpu_to_le32(period * 8);
+				descriptors[half].reserved = 0;
+			}
+			memset(c->ring[pair], 0, c->frames * 8);
+		}
+		memset(s->runtime->dma_area, 0,
+		       c->frames * maya_sample_bytes(s->runtime->format) * 4);
+		dma_wmb();
+		/* Give playback IRQs a scheduling point between input resets. */
+		for (pair = 0; pair < 2; ++pair) {
+			spin_lock_irqsave(&m->lock, flags);
+			err = m->fault || m->removing || m->suspended ?
+				-EIO : maya_capture_rearm(m, pair);
+			spin_unlock_irqrestore(&m->lock, flags);
+			if (err)
+				break;
+		}
+	}
+	mutex_unlock(&m->codec_lock);
+	return err;
+}
+
+static int maya_capture_trigger(struct snd_pcm_substream *s, int cmd)
+{
+	struct maya *m = snd_pcm_substream_chip(s);
+	unsigned long flags;
+	int err = 0, pair;
+
+	spin_lock_irqsave(&m->lock, flags);
+	if (m->fault || m->removing || m->suspended) {
+		err = -EIO;
+		goto out;
+	}
+	switch (cmd) {
+	case SNDRV_PCM_TRIGGER_START:
+		for (pair = 1; pair >= 0; --pair) {
+			unsigned int b = 0x80 + pair * 0x20;
+
+			mw8(m, b + 3, 0xff);
+			/* Independent capture needs its own period IRQ source. */
+			mw8(m, 0x192 + pair * 4, pair ? 3 : 7);
+			if (!(mr32(m, b) & 2))
+				mw8(m, b, 2);
+		}
+		m->capture.running = true;
+
+		break;
+	case SNDRV_PCM_TRIGGER_STOP:
+	case SNDRV_PCM_TRIGGER_SUSPEND:
+		err = maya_capture_stop(m);
+		break;
+	default:
+		err = -EINVAL;
+	}
+out:
+	spin_unlock_irqrestore(&m->lock, flags);
+	return err;
+}
+
+static snd_pcm_uframes_t maya_capture_pointer(struct snd_pcm_substream *s)
+{
+	struct maya *m = snd_pcm_substream_chip(s);
+
+	return READ_ONCE(m->capture.position);
+}
+
+static const struct snd_pcm_ops maya_capture_ops = {
+	.open = maya_capture_open,
+	.close = maya_capture_close,
+	.ioctl = snd_pcm_lib_ioctl,
+	.hw_params = maya_hw_params,
+	.hw_free = maya_hw_free,
+	.prepare = maya_capture_prepare,
+	.trigger = maya_capture_trigger,
+	.sync_stop = maya_sync_stop,
+	.pointer = maya_capture_pointer,
+};
+
+enum { CTL_DAC, CTL_MIX_VOLUME, CTL_MIX_SWITCH, CTL_DAC_SWITCH };
+
+static int maya_ctl_info(struct snd_kcontrol *k, struct snd_ctl_elem_info *info)
+{
+	unsigned int kind = k->private_value >> 8;
+
+	if (kind == CTL_MIX_SWITCH || kind == CTL_DAC_SWITCH)
+		return snd_ctl_boolean_mono_info(k, info);
+	info->type = SNDRV_CTL_ELEM_TYPE_INTEGER;
+	info->count = kind == CTL_DAC ? 2 : 1;
+	info->value.integer.min = 0;
+	info->value.integer.max = kind == CTL_DAC ? 255 : 48;
+	return 0;
+}
+
+static int maya_ctl_get(struct snd_kcontrol *k, struct snd_ctl_elem_value *v)
+{
+	struct maya *m = snd_kcontrol_chip(k);
+	unsigned int pair = k->private_value & 1;
+	unsigned int kind = k->private_value >> 8;
+
+	mutex_lock(&m->codec_lock);
+	if (kind == CTL_DAC) {
+		v->value.integer.value[0] = m->dac[pair][0];
+		v->value.integer.value[1] = m->dac[pair][1];
+	} else if (kind == CTL_DAC_SWITCH) {
+		v->value.integer.value[0] = m->dac_enabled[pair];
+	} else {
+		v->value.integer.value[0] = kind == CTL_MIX_VOLUME ?
+			m->mix[pair] : m->mix_enabled[pair];
+	}
+	mutex_unlock(&m->codec_lock);
+	return 0;
+}
+
+static int maya_ctl_put(struct snd_kcontrol *k, struct snd_ctl_elem_value *v)
+{
+	struct maya *m = snd_kcontrol_chip(k);
+	unsigned int pair = k->private_value & 1;
+	unsigned int kind = k->private_value >> 8;
+	long a = v->value.integer.value[0], b = v->value.integer.value[1];
+	unsigned int level;
+	bool enabled;
+	int err = 0, changed = 0;
+
+	if (a < 0 || a > (kind == CTL_DAC ? 255 : kind == CTL_MIX_VOLUME ? 48 : 1) ||
+	    (kind == CTL_DAC && (b < 0 || b > 255)))
+		return -EINVAL;
+	mutex_lock(&m->codec_lock);
+	if (READ_ONCE(m->fault) || READ_ONCE(m->removing) || READ_ONCE(m->suspended)) {
+		err = -EIO;
+		goto out;
+	}
+	if (kind == CTL_DAC) {
+		if (m->dac[pair][0] != a) {
+			err = maya_codec_write(m, pair, 3, 0x100 | a);
+			if (err)
+				goto out;
+			m->dac[pair][0] = a;
+			changed = 1;
+		}
+		if (m->dac[pair][1] != b) {
+			err = maya_codec_write(m, pair, 4, 0x100 | b);
+			if (err)
+				goto out;
+			m->dac[pair][1] = b;
+			changed = 1;
+		}
+	} else if (kind == CTL_DAC_SWITCH) {
+		changed = m->dac_enabled[pair] != a;
+		if (changed) {
+			/* R22 gates this DAC's direct and outgoing crossmix paths.
+			 * Preserve the separately controlled analogue input monitor path.
+			 */
+			err = maya_codec_write(m, pair, 22, (a ? 1 : 0) |
+					       (m->monitor[pair] &&
+						m->input_enabled[pair] ? 4 : 0));
+			if (err)
+				goto out;
+			m->dac_enabled[pair] = a;
+		}
+	} else {
+		level = kind == CTL_MIX_VOLUME ? a : m->mix[pair];
+		enabled = kind == CTL_MIX_SWITCH ? a : m->mix_enabled[pair];
+		changed = level != m->mix[pair] || enabled != m->mix_enabled[pair];
+		if (changed) {
+			err = maya_codec_write(m, 1 - pair, 2,
+					       0x100 | (enabled ? level + 0x49 : 0));
+			if (err)
+				goto out;
+			m->mix[pair] = level;
+			m->mix_enabled[pair] = enabled;
+		}
+	}
+out:
+	mutex_unlock(&m->codec_lock);
+	return err ? err : changed;
+}
+
+static const DECLARE_TLV_DB_SCALE(dac_db, -12750, 50, 1);
+static const DECLARE_TLV_DB_SCALE(mix_db, -4800, 100, 0);
+
+#define MAYA_CONTROL(label, kind, pair, scale) { \
+	.iface = SNDRV_CTL_ELEM_IFACE_MIXER, .name = label, \
+	.access = SNDRV_CTL_ELEM_ACCESS_READWRITE | \
+		((kind) == CTL_MIX_SWITCH || (kind) == CTL_DAC_SWITCH ? \
+		 0 : SNDRV_CTL_ELEM_ACCESS_TLV_READ), \
+	.info = maya_ctl_info, .get = maya_ctl_get, .put = maya_ctl_put, \
+	.private_value = ((kind) << 8) | (pair), .tlv.p = scale }
+
+static const struct snd_kcontrol_new maya_controls[] = {
+	MAYA_CONTROL("Output 1-2 Playback Volume", CTL_DAC, 0, dac_db),
+	MAYA_CONTROL("Output 3-4 Playback Volume", CTL_DAC, 1, dac_db),
+	MAYA_CONTROL("DAC 1-2 Playback Switch", CTL_DAC_SWITCH, 0, NULL),
+	MAYA_CONTROL("DAC 3-4 Playback Switch", CTL_DAC_SWITCH, 1, NULL),
+	MAYA_CONTROL("Output 1-2 Crossmix Playback Volume", CTL_MIX_VOLUME, 0, mix_db),
+	MAYA_CONTROL("Output 1-2 Crossmix Playback Switch", CTL_MIX_SWITCH, 0, NULL),
+	MAYA_CONTROL("Output 3-4 Crossmix Playback Volume", CTL_MIX_VOLUME, 1, mix_db),
+	MAYA_CONTROL("Output 3-4 Crossmix Playback Switch", CTL_MIX_SWITCH, 1, NULL),
+};
+
+/* Input register facts checked against original 0x144d0/0x14580/0x15c00
+ * and WM8776 rev4.1. No mono/LRBOTH (R21 bit8), ALC or AUX routing.
+ */
+enum { INPUT_VOLUME, INPUT_GAIN, INPUT_SWITCH, INPUT_SOURCE, INPUT_MONITOR };
+
+static u16 maya_input_mux(struct maya *m, unsigned int pair)
+{
+	u16 mux = m->input_source[pair] ? 8 : 2;
+
+	/* The WM8776 input PGA mute also gates the analog monitor path. */
+	if (!m->input_enabled[pair] || !m->input_volume[pair][0])
+		mux |= BIT(7);
+	if (!m->input_enabled[pair] || !m->input_volume[pair][1])
+		mux |= BIT(6);
+	return mux;
+}
+
+static int maya_input_levels(struct maya *m, unsigned int pair)
+{
+	unsigned int ch;
+	int err;
+
+	for (ch = 0; ch < 2; ++ch) {
+		unsigned int raw = 62 + m->input_pga_volume[pair][ch] + m->input_gain[pair];
+
+		err = maya_codec_write(m, pair, 14 + ch, 0x100 | raw);
+		if (err)
+			return err;
+	}
+	return 0;
+}
+
+static int maya_input_info(struct snd_kcontrol *k, struct snd_ctl_elem_info *info)
+{
+	unsigned int kind = k->private_value >> 8, pair = k->private_value & 1;
+	static const char * const sources12[] = {"Line", "Mic"};
+	static const char * const sources34[] = {"Line", "Hi-Z"};
+
+	if (kind == INPUT_SOURCE)
+		return snd_ctl_enum_info(info, 1, 2, pair ? sources34 : sources12);
+	if (kind >= INPUT_SWITCH && kind != INPUT_SOURCE)
+		return snd_ctl_boolean_mono_info(k, info);
+	info->type = SNDRV_CTL_ELEM_TYPE_INTEGER;
+	info->count = kind == INPUT_VOLUME ? 2 : 1;
+	info->value.integer.min = 0;
+	info->value.integer.max = kind == INPUT_VOLUME ? 145 : 48;
+	return 0;
+}
+
+static int maya_input_get(struct snd_kcontrol *k, struct snd_ctl_elem_value *v)
+{
+	struct maya *m = snd_kcontrol_chip(k);
+	unsigned int pair = k->private_value & 1, kind = k->private_value >> 8;
+
+	mutex_lock(&m->codec_lock);
+	switch (kind) {
+	case INPUT_VOLUME:
+		v->value.integer.value[0] = m->input_volume[pair][0];
+		v->value.integer.value[1] = m->input_volume[pair][1];
+		break;
+	case INPUT_GAIN:
+		v->value.integer.value[0] = m->input_gain[pair];
+		break;
+	case INPUT_SOURCE:
+		v->value.enumerated.item[0] = m->input_source[pair];
+		break;
+	case INPUT_SWITCH:
+		v->value.integer.value[0] = m->input_enabled[pair];
+		break;
+	case INPUT_MONITOR:
+		v->value.integer.value[0] = m->monitor[pair];
+		break;
+	}
+	mutex_unlock(&m->codec_lock);
+	return 0;
+}
+
+static int maya_input_put(struct snd_kcontrol *k, struct snd_ctl_elem_value *v)
+{
+	struct maya *m = snd_kcontrol_chip(k);
+	unsigned int pair = k->private_value & 1, kind = k->private_value >> 8;
+	long a = kind == INPUT_SOURCE ? v->value.enumerated.item[0] : v->value.integer.value[0];
+	long b = v->value.integer.value[1];
+	unsigned long flags;
+	u8 gpio;
+	int err = 0, changed = 0;
+
+	if (a < 0 || a > (kind == INPUT_VOLUME ? 145 : kind == INPUT_GAIN ? 48 : 1) ||
+	    (kind == INPUT_VOLUME && (b < 0 || b > 145)))
+		return -EINVAL;
+	mutex_lock(&m->codec_lock);
+	if (READ_ONCE(m->fault) || READ_ONCE(m->removing) || READ_ONCE(m->suspended)) {
+		err = -EIO;
+		goto out;
+	}
+	switch (kind) {
+	case INPUT_VOLUME:
+		changed = m->input_volume[pair][0] != a || m->input_volume[pair][1] != b;
+		if (changed) {
+			u16 old_mux = maya_input_mux(m, pair);
+			u16 mux;
+
+			/* Retain the last nonzero PGA level across mute and resume. */
+			if (a)
+				m->input_pga_volume[pair][0] = a;
+			if (b)
+				m->input_pga_volume[pair][1] = b;
+			WRITE_ONCE(m->input_volume[pair][0], a);
+			WRITE_ONCE(m->input_volume[pair][1], b);
+			err = maya_input_levels(m, pair);
+			mux = maya_input_mux(m, pair);
+			if (!err && mux != old_mux)
+				err = maya_codec_write(m, pair, 21, mux);
+		}
+		break;
+	case INPUT_GAIN:
+		changed = m->input_gain[pair] != a;
+		if (changed) {
+			m->input_gain[pair] = a;
+			err = maya_input_levels(m, pair);
+		}
+		break;
+	case INPUT_SWITCH:
+		changed = m->input_enabled[pair] != a;
+		if (changed) {
+			m->input_enabled[pair] = a;
+			err = maya_codec_write(m, pair, 21, maya_input_mux(m, pair));
+			if (!err)
+				err = maya_codec_write(m, pair, 22, (m->dac_enabled[pair] ? 1 : 0) |
+					(m->monitor[pair] && a ? 4 : 0));
+		}
+		break;
+	case INPUT_MONITOR:
+		changed = m->monitor[pair] != a;
+		if (changed) {
+			err = maya_codec_write(m, pair, 22,
+					       (m->dac_enabled[pair] ? 1 : 0) |
+					       (a && m->input_enabled[pair] ? 4 : 0));
+			if (!err)
+				m->monitor[pair] = a;
+		}
+		break;
+	case INPUT_SOURCE:
+		changed = m->input_source[pair] != a;
+		if (!changed)
+			break;
+		/* Disconnect bypass during the switch and keep phantom off. */
+		err = maya_codec_write(m, pair, 22, m->dac_enabled[pair] ? 1 : 0);
+		if (err)
+			break;
+		gpio = mr8(m, 0x481);
+		if (!pair)
+			gpio = (gpio & ~0x50) | (a ? 0x10 : 0);
+		else
+			gpio = (gpio & ~0x20) | (a ? 0 : 0x20);
+		mw8(m, 0x481, gpio);
+		m->input_source[pair] = a;
+		err = maya_codec_write(m, pair, 21, maya_input_mux(m, pair));
+		if (!err)
+			err = maya_codec_write(m, pair, 22,
+					       (m->dac_enabled[pair] ? 1 : 0) |
+				(m->monitor[pair] &&
+						m->input_enabled[pair] ? 4 : 0));
+		break;
+	}
+	if (err) {
+		/* A partial codec transaction leaves the actual state uncertain.
+		 * Fail closed: phantom off, all DMA stopped, require module reload.
+		 */
+		spin_lock_irqsave(&m->lock, flags);
+		maya_fatal(m);
+		spin_unlock_irqrestore(&m->lock, flags);
+	}
+out:
+	mutex_unlock(&m->codec_lock);
+	return err ? err : changed;
+}
+
+static const DECLARE_TLV_DB_SCALE(input_volume_db, -7250, 50, 1);
+static const DECLARE_TLV_DB_SCALE(input_gain_db, 0, 50, 0);
+#define MAYA_INPUT(label, kind, pair, scale) { \
+	.iface = SNDRV_CTL_ELEM_IFACE_MIXER, .name = label, \
+	.access = SNDRV_CTL_ELEM_ACCESS_READWRITE | \
+		((kind) <= INPUT_GAIN ? SNDRV_CTL_ELEM_ACCESS_TLV_READ : 0), \
+	.info = maya_input_info, .get = maya_input_get, .put = maya_input_put, \
+	.private_value = ((kind) << 8) | (pair), .tlv.p = scale }
+static const struct snd_kcontrol_new maya_input_controls[] = {
+	MAYA_INPUT("Input 1-2 Capture Volume", INPUT_VOLUME, 0, input_volume_db),
+	MAYA_INPUT("Input 3-4 Capture Volume", INPUT_VOLUME, 1, input_volume_db),
+	MAYA_INPUT("Input 1-2 Capture Gain", INPUT_GAIN, 0, input_gain_db),
+	MAYA_INPUT("Input 3-4 Capture Gain", INPUT_GAIN, 1, input_gain_db),
+	MAYA_INPUT("Input 1-2 Capture Switch", INPUT_SWITCH, 0, NULL),
+	MAYA_INPUT("Input 3-4 Capture Switch", INPUT_SWITCH, 1, NULL),
+	MAYA_INPUT("Input 1-2 Capture Source", INPUT_SOURCE, 0, NULL),
+	MAYA_INPUT("Input 3-4 Capture Source", INPUT_SOURCE, 1, NULL),
+	MAYA_INPUT("Input 1-2 Monitor Playback Switch", INPUT_MONITOR, 0, NULL),
+	MAYA_INPUT("Input 3-4 Monitor Playback Switch", INPUT_MONITOR, 1, NULL),
+};
+
+static void maya_free(struct snd_card *card)
+{
+	struct maya *m = card->private_data;
+	unsigned long flags;
+	unsigned int pair;
+
+	spin_lock_irqsave(&m->lock, flags);
+	m->removing = true;
+	if (m->enabled)
+		maya_fatal(m);
+	spin_unlock_irqrestore(&m->lock, flags);
+	cancel_work_sync(&m->fault_work);
+	if (m->irq_requested)
+		free_irq(m->pci->irq, m);
+	if (m->enabled)
+		pci_wait_for_pending_transaction(m->pci);
+	for (pair = 0; pair < 2; ++pair)
+		if (m->capture.ring[pair])
+			dma_free_coherent(&m->pci->dev, MAYA_PAIR_BYTES_MAX,
+					  m->capture.ring[pair], m->capture.dma[pair]);
+	for (pair = 0; pair < 2; ++pair)
+		if (m->ring[pair])
+			dma_free_coherent(&m->pci->dev, MAYA_PAIR_BYTES_MAX,
+					  m->ring[pair], m->ring_dma[pair]);
+	if (m->desc_allocation)
+		dma_free_coherent(&m->pci->dev, MAYA_DESC_BYTES,
+				  m->desc_allocation, m->desc_dma);
+	if (m->io)
+		pci_iounmap(m->pci, m->io);
+	if (m->regions)
+		pci_release_regions(m->pci);
+	if (m->enabled)
+		pci_disable_device(m->pci);
+}
+
+static int maya_probe(struct pci_dev *pci, const struct pci_device_id *id)
+{
+	struct snd_card *card;
+	struct maya *m;
+	unsigned int pair, offset;
+	int err;
+
+	err = snd_card_new(&pci->dev, -1, "MAYA44e", THIS_MODULE, sizeof(*m), &card);
+	if (err)
+		return err;
+	m = card->private_data;
+	m->pci = pci;
+	m->period_frames = MAYA_DEFAULT_PERIOD;
+	m->buffer_frames = MAYA_DEFAULT_PERIOD * 2;
+	INIT_WORK(&m->fault_work, maya_fault_work);
+	spin_lock_init(&m->lock);
+	mutex_init(&m->codec_lock);
+	card->private_free = maya_free;
+	err = pci_enable_device_mem(pci);
+	if (err)
+		goto fail;
+	m->enabled = true;
+	pci_clear_master(pci);
+	pci_intx(pci, 0);
+	err = pci_request_regions(pci, "snd-maya44e");
+	if (err)
+		goto fail;
+	m->regions = true;
+	if (!(pci_resource_flags(pci, 0) & IORESOURCE_MEM) || pci_resource_len(pci, 0) < 0x500) {
+		err = -ENODEV;
+		goto fail;
+	}
+	err = dma_set_mask_and_coherent(&pci->dev, DMA_BIT_MASK(32));
+	if (err)
+		goto fail;
+	m->io = pci_iomap(pci, 0, 0);
+	if (!m->io) {
+		err = -ENOMEM;
+		goto fail;
+	}
+	m->desc_allocation = dma_alloc_coherent(&pci->dev, MAYA_DESC_BYTES,
+						&m->desc_dma, GFP_KERNEL);
+	if (!m->desc_allocation) {
+		err = -ENOMEM;
+		goto fail;
+	}
+	memset(m->desc_allocation, 0, MAYA_DESC_BYTES);
+	m->table_dma = (m->desc_dma + 0x100) & ~((dma_addr_t)0xff);
+	offset = m->table_dma - m->desc_dma;
+	m->table = m->desc_allocation + offset;
+	for (pair = 0; pair < 2; ++pair) {
+		m->ring[pair] = dma_alloc_coherent(&pci->dev, MAYA_PAIR_BYTES_MAX,
+						   &m->ring_dma[pair], GFP_KERNEL);
+		if (!m->ring[pair]) {
+			err = -ENOMEM;
+			goto fail;
+		}
+		memset(m->ring[pair], 0, MAYA_PAIR_BYTES_MAX);
+		m->dac[pair][1] = 0xc3;
+		m->dac[pair][0] = 0xc3;
+		m->dac_enabled[pair] = true; /* Matches the initial R22=1. */
+		m->capture.ring[pair] = dma_alloc_coherent(&pci->dev, MAYA_PAIR_BYTES_MAX,
+							   &m->capture.dma[pair], GFP_KERNEL);
+		if (!m->capture.ring[pair]) {
+			err = -ENOMEM;
+			goto fail;
+		}
+		memset(m->capture.ring[pair], 0, MAYA_PAIR_BYTES_MAX);
+		m->input_volume[pair][1] = 145;
+		m->input_volume[pair][0] = 145;
+		m->input_pga_volume[pair][1] = m->input_volume[pair][1];
+		m->input_pga_volume[pair][0] = m->input_volume[pair][0];
+		m->input_enabled[pair] = true;
+		m->mix[pair] = 18; /* -30 dB when explicitly enabled later. */
+	}
+	maya_configure_buffer(m, MAYA_DEFAULT_PERIOD);
+	err = maya_controller_init(m);
+	if (err) {
+		dev_err(&pci->dev, "controller initialization failed: %d\n", err);
+		goto fail;
+	}
+	err = request_irq(pci->irq, maya_irq, IRQF_SHARED, "snd-maya44e", m);
+	if (err)
+		goto fail;
+	m->irq_requested = true;
+	err = snd_pcm_new(card, "MAYA44e", 0, 1, 1, &m->pcm);
+	if (err)
+		goto fail;
+	m->pcm->private_data = m;
+	strscpy(m->pcm->name, "MAYA44e Analog");
+	snd_pcm_set_ops(m->pcm, SNDRV_PCM_STREAM_PLAYBACK, &maya_pcm_ops);
+	snd_pcm_set_ops(m->pcm, SNDRV_PCM_STREAM_CAPTURE, &maya_capture_ops);
+	err = snd_pcm_set_managed_buffer_all(m->pcm, SNDRV_DMA_TYPE_VMALLOC,
+					     NULL, MAYA_PCM_BYTES_MAX, MAYA_PCM_BYTES_MAX);
+	if (err)
+		goto fail;
+	for (pair = 0; pair < ARRAY_SIZE(maya_controls); ++pair) {
+		err = snd_ctl_add(card, snd_ctl_new1(&maya_controls[pair], m));
+		if (err)
+			goto fail;
+	}
+	for (pair = 0; pair < ARRAY_SIZE(maya_input_controls); ++pair) {
+		err = snd_ctl_add(card, snd_ctl_new1(&maya_input_controls[pair], m));
+		if (err)
+			goto fail;
+	}
+	strscpy(card->driver, "MAYA44e");
+	strscpy(card->shortname, "ESI MAYA44e");
+	snprintf(card->longname, sizeof(card->longname),
+		 "ESI MAYA44e at %s irq %d", pci_name(pci), pci->irq);
+	pci_set_drvdata(pci, card);
+	m->irq_window = jiffies;
+	pci_set_master(pci);
+	pci_intx(pci, 1);
+	err = snd_card_register(card);
+	if (err)
+		goto fail;
+	return 0;
+fail:
+	pci_set_drvdata(pci, NULL);
+	snd_card_free(card);
+	return err;
+}
+
+static void maya_remove(struct pci_dev *pci)
+{
+	struct snd_card *card = pci_get_drvdata(pci);
+
+	if (card) {
+		snd_card_disconnect(card);
+		snd_card_free(card);
+		pci_set_drvdata(pci, NULL);
+	}
+}
+
+/* codec_lock held; IRQ and all PCM/controls/MMIO readers remain gated by
+ * suspended until the complete board state is restored. PCI core restores
+ * power/config space before calling resume; DMA stays disabled here.
+ */
+static int maya_restore_after_sleep(struct maya *m)
+{
+	unsigned int pair;
+	u8 gpio;
+	int err;
+
+	memset(m->ring[0], 0, MAYA_PAIR_BYTES_MAX);
+	memset(m->ring[1], 0, MAYA_PAIR_BYTES_MAX);
+	memset(m->capture.ring[0], 0, MAYA_PAIR_BYTES_MAX);
+	memset(m->capture.ring[1], 0, MAYA_PAIR_BYTES_MAX);
+	maya_configure_buffer(m, m->period_frames);
+	m->capture.position = 0;
+
+	/* A retained rate cache must not suppress clock programming after S3. */
+	m->rate = 0;
+	err = maya_controller_init(m);
+	if (err)
+		return err;
+	err = maya_set_rate(m, m->suspend_rate);
+	if (err)
+		return err;
+	gpio = mr8(m, 0x481) & ~0x70;
+	gpio |= (m->input_source[0] == 1 ? 0x10 : 0) |
+		(m->input_source[1] ? 0 : 0x20);
+	mw8(m, 0x481, gpio);
+	for (pair = 0; pair < 2; ++pair) {
+		err = maya_input_levels(m, pair);
+		if (err)
+			return err;
+		err = maya_codec_write(m, pair, 21, maya_input_mux(m, pair));
+		if (err)
+			return err;
+		err = maya_codec_write(m, pair, 22, (m->dac_enabled[pair] ? 1 : 0) |
+			(m->monitor[pair] &&
+						m->input_enabled[pair] ? 4 : 0));
+		if (err)
+			return err;
+		err = maya_codec_write(m, 1 - pair, 2,
+				       0x100 | (m->mix_enabled[pair] ? m->mix[pair] + 0x49 : 0));
+		if (err)
+			return err;
+	}
+	if (maya_valid_period(m->capture.period)) {
+		for (pair = 0; pair < 2; ++pair) {
+			err = maya_capture_rearm(m, pair);
+			if (err)
+				return err;
+		}
+	}
+	dma_wmb();
+	return 0;
+}
+
+static int maya_suspend(struct device *dev)
+{
+	struct snd_card *card = dev_get_drvdata(dev);
+	struct maya *m = card->private_data;
+	unsigned long flags;
+
+	snd_power_change_state(card, SNDRV_CTL_POWER_D3hot);
+	/* ALSA stream locks must be acquired before our register/codec locks. */
+	snd_pcm_suspend_all(m->pcm);
+	mutex_lock(&m->codec_lock);
+	spin_lock_irqsave(&m->lock, flags);
+	if (!m->suspended) {
+		m->suspend_rate = m->rate;
+		maya_quiesce(m, true);
+		m->suspended = true;
+	}
+	spin_unlock_irqrestore(&m->lock, flags);
+	synchronize_irq(m->pci->irq);
+	mutex_unlock(&m->codec_lock);
+	/* The gate prevents new work; complete any pending peer notification. */
+	flush_work(&m->fault_work);
+	return 0;
+}
+
+static int maya_resume(struct device *dev)
+{
+	struct snd_card *card = dev_get_drvdata(dev);
+	struct maya *m = card->private_data;
+	unsigned long flags;
+	bool mmio_active;
+	int err;
+
+	mutex_lock(&m->codec_lock);
+	if (!m->suspended) {
+		mutex_unlock(&m->codec_lock);
+		return 0;
+	}
+	mmio_active = m->pci->current_state == PCI_D0 &&
+		!pci_channel_offline(m->pci) && pci_device_is_present(m->pci);
+	if (!mmio_active) {
+		err = -ENODEV;
+		goto fail;
+	}
+	if (m->fault || m->removing) {
+		err = -EIO;
+		goto fail;
+	}
+	pci_intx(m->pci, 0);
+	pci_clear_master(m->pci);
+	err = maya_restore_after_sleep(m);
+	if (err)
+		goto fail;
+	spin_lock_irqsave(&m->lock, flags);
+	m->irq_window = jiffies;
+	m->irq_window_handled = 0;
+
+	m->suspended = false;
+	pci_set_master(m->pci);
+	pci_intx(m->pci, 1);
+	spin_unlock_irqrestore(&m->lock, flags);
+	mutex_unlock(&m->codec_lock);
+	snd_power_change_state(card, SNDRV_CTL_POWER_D0);
+	return 0;
+fail:
+	spin_lock_irqsave(&m->lock, flags);
+	m->fault = true;
+	/* PCI may be back in D0 even while the software suspend gate is set. */
+	maya_quiesce(m, mmio_active && !m->removing && !pci_channel_offline(m->pci));
+	spin_unlock_irqrestore(&m->lock, flags);
+	mutex_unlock(&m->codec_lock);
+	/* Wake control operations waiting for D0 on the failed card. */
+	snd_card_disconnect(card);
+	dev_err(dev, "resume failed: %d; DMA and interrupts disabled\n", err);
+	return err;
+}
+
+static DEFINE_SIMPLE_DEV_PM_OPS(maya_pm_ops, maya_suspend, maya_resume);
+
+static const struct pci_device_id maya_ids[] = {
+	{ PCI_DEVICE_SUB(0x19fe, 0x7000, 0x0e51, 0x0001) },
+	{ }
+};
+MODULE_DEVICE_TABLE(pci, maya_ids);
+
+static struct pci_driver maya_driver = {
+	.name = "snd-maya44e",
+	.id_table = maya_ids,
+	.probe = maya_probe,
+	.remove = maya_remove,
+	.driver.pm = pm_sleep_ptr(&maya_pm_ops),
+};
+module_pci_driver(maya_driver);
+
+MODULE_AUTHOR("MAYA44e Linux reverse-engineering project");
+MODULE_DESCRIPTION("ESI MAYA44e analog audio driver");
+MODULE_LICENSE("GPL");

---
base-commit: ec925d3740159f4b4bd3b7640be5d0d2b4664106
change-id: 20261111-codex-alsa-maya44e-2c41718770fb
prerequisite-patch-id: a43255e8bd12f0cc8a3072eaa97a986ad7a0be72

Best regards,
-- 
Nordschamane <nordschamane1@proton.me>

