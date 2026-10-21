From: Henrik Enquist <henrik.enquist@gmail.com>
Date: Wed, 21 Oct 2026 09:46:46 +0200
Subject: [PATCH 2/2] selftests/alsa: Check the aloop PCM Slave controls for
 a matching playback
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-aloop-slave-controls-v1-2-62297727177f@gmail.com>
References: <20261021-aloop-slave-controls-v1-0-62297727177f@gmail.com>
In-Reply-To: <20261021-aloop-slave-controls-v1-0-62297727177f@gmail.com>
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Mark Brown <broonie@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Henrik Enquist <henrik.enquist@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792568804; l=2678;
 i=henrik.enquist@gmail.com; s=20261003; h=from:subject:message-id;
 bh=VSTLeRkvDN+ZF+CMMCj3hMx1dw85nE2aZG16Hn9p9sY=;
 b=4K+sccxtaLcCx3g/oIrpq0WvrzVqWT2n9N/fZgRhtxxFFt3xzzSD4MXm05dmLtnzT3DmtJpJQ
 y1idqp+KfGtBDCvZNBWaTTPywRrxhYCq5wW+kUXwFGpI/PEv4qMbf2M
X-Developer-Key: i=henrik.enquist@gmail.com; a=ed25519;
 pk=ctrSXwtuuiWIZbc1qNzu+n+1PkhB/a+2nlRyXd5j2pg=
X-Endpoint-Received: by B4 Relay for henrik.enquist@gmail.com/20261003 with auth_id=1105
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a test that starts a playback with the same parameters as a running
capture, and checks that the capture keeps running and that the
"PCM Slave" controls report the playback's parameters, with a value
event for each control that changed. Before the previous patch, the
controls keep the parameters of the earlier stream and the test fails.

Signed-off-by: Henrik Enquist <henrik.enquist@gmail.com>
---
 tools/testing/selftests/alsa/aloop-test.c | 40 +++++++++++++++++++++++++++++++
 1 file changed, 40 insertions(+)

diff --git a/tools/testing/selftests/alsa/aloop-test.c b/tools/testing/selftests/alsa/aloop-test.c
index a58b9fdbdc..74d6ccc127 100644
--- a/tools/testing/selftests/alsa/aloop-test.c
+++ b/tools/testing/selftests/alsa/aloop-test.c
@@ -323,6 +323,46 @@ TEST_F(aloop, params_change_stops_capture_with_notify) {
 	snd_pcm_close(capt);
 }
 
+/*
+ * A playback that joins a running capture with the same parameters doesn't
+ * stop it, and the "PCM Slave" controls still report the playback's
+ * parameters rather than those of an earlier stream.
+ */
+TEST_F(aloop, matching_playback_updates_controls) {
+	snd_pcm_t *capt, *play;
+	unsigned int events;
+
+	/* Leave the controls at other parameters than the ones used below. */
+	ASSERT_EQ(open_pcm(&play, self->play_name, SND_PCM_STREAM_PLAYBACK, &playback_params), 0);
+	ASSERT_EQ(start_playback(play, &playback_params), 0);
+	snd_pcm_close(play);
+
+	ASSERT_EQ(set_notify(self->ctl, false), 0);
+	ASSERT_EQ(open_pcm(&capt, self->capt_name, SND_PCM_STREAM_CAPTURE, &capture_params), 0);
+	ASSERT_EQ(snd_pcm_start(capt), 0);
+	read_events(self->ctl);
+
+	ASSERT_EQ(open_pcm(&play, self->play_name, SND_PCM_STREAM_PLAYBACK, &capture_params), 0);
+	ASSERT_EQ(start_playback(play, &capture_params), 0);
+
+	EXPECT_EQ(snd_pcm_state(capt), SND_PCM_STATE_RUNNING);
+
+	EXPECT_EQ(cable_ctl_get(self->ctl, "PCM Slave Active"), 1);
+	EXPECT_EQ(cable_ctl_get(self->ctl, "PCM Slave Format"), capture_params.format);
+	EXPECT_EQ(cable_ctl_get(self->ctl, "PCM Slave Rate"), capture_params.rate);
+	EXPECT_EQ(cable_ctl_get(self->ctl, "PCM Slave Channels"), capture_params.channels);
+	EXPECT_EQ(cable_ctl_get(self->ctl, "PCM Slave Access Mode"), 0);
+
+	events = read_events(self->ctl);
+	EXPECT_TRUE(events & EV_FORMAT);
+	EXPECT_TRUE(events & EV_RATE);
+	EXPECT_TRUE(events & EV_CHANNELS);
+	EXPECT_TRUE(events & EV_ACCESS);
+
+	snd_pcm_close(play);
+	snd_pcm_close(capt);
+}
+
 /* With notify, a capture opened second is still pinned to the playback's parameters. */
 TEST_F(aloop, capture_constrained_with_notify) {
 	struct probe_result res;

-- 
2.53.0

