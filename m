From: Anuj Bolewar <bolewara@gmail.com>
Date: Mon, 03 Aug 2026 22:50:47 +0530
Subject: [PATCH] media: ttusb-dec: bound result copy in
 ttusb_dec_send_command
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-fix-ttusb-dec-cmd-result-overflow-v1-1-4a3695a981f7@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWNSw7CMAwFr1J5jaUQykdcBbEgjgNBpUF2UpCq3
 h0DeqtZvJkZlCWzwrGbQXjKmstosF51QLfLeGXM0Ri88zt3cBtM+Y21Ng0YmZAeEYW1DRXLxJK
 G8sJ9sPlA29T3YJ6nsJ1+jdP5z9rCnal+xbAsHyir0NGFAAAA
X-Change-ID: 20260803-fix-ttusb-dec-cmd-result-overflow-7b7b72bc5f44
To: Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzkaller-bugs@googlegroups.com, 
 syzbot+ac9880be0b0b1a5f54d6@syzkaller.appspotmail.com, 
 Anuj Bolewar <bolewara@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785777646; l=9353;
 i=bolewara@gmail.com; s=20260802; h=from:subject:message-id;
 bh=dnofLJoU8gMJ7/injRh1rxquFHIdxkMMsLjNYYG+bpg=;
 b=qinybXIZjMcses9IJuVllbkFFWyprDcvtM5l5McJjL0EJiD23NBb1dwYYEZ6lDLPJ6yF/rQZm
 PIWl2ezTKhFALqTQnsMVrzOAqGTKrPkOaI/z4YkPEf5qrFmp2oAQvSE
X-Developer-Key: i=bolewara@gmail.com; a=ed25519;
 pk=XxcXxqFWk9xQziyNEfhS6NRJQR1shqHRRYzkbaYamm0=
X-Endpoint-Received: by B4 Relay for bolewara@gmail.com/20260802 with auth_id=907
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The result length byte in the response packet is controlled by the
device and may not match the number of bytes actually received, nor the
size of the caller's buffer. A malicious device can therefore make
memcpy() read past the end of the response buffer (which is
COMMAND_PACKET_SIZE + 4 bytes, leaving only 60 bytes of payload after
the header) and write past the end of cmd_result, which is only 4 bytes
for the FE read_status path.

Cap the copy to both the received payload length and the caller's
buffer size, and report the capped length to the caller.

Reported-by: syzbot+ac9880be0b0b1a5f54d6@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=ac9880be0b0b1a5f54d6
Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Signed-off-by: Anuj Bolewar <bolewara@gmail.com>
---
syzbot reports a WARNING in ttusb_dec_send_command: a malformed USB
device returns a reply whose length byte is larger than the data
actually received, so ttusb_dec_send_command() over-reads its response
buffer and can also over-write the caller's result buffer (the FE
read_status path passes only 4 bytes).

This series bounds the memcpy() by both the received payload length and
the caller's buffer size, and reports the capped length back to the
caller.

Link: https://syzkaller.appspot.com/bug?extid=ac9880be0b0b1a5f54d6
---
 drivers/media/usb/ttusb-dec/ttusb_dec.c  | 53 ++++++++++++++++++++++----------
 drivers/media/usb/ttusb-dec/ttusbdecfe.c |  9 +++---
 drivers/media/usb/ttusb-dec/ttusbdecfe.h |  3 +-
 3 files changed, 43 insertions(+), 22 deletions(-)

diff --git a/drivers/media/usb/ttusb-dec/ttusb_dec.c b/drivers/media/usb/ttusb-dec/ttusb_dec.c
index 825a3875989..0a4750c2d12 100644
--- a/drivers/media/usb/ttusb-dec/ttusb_dec.c
+++ b/drivers/media/usb/ttusb-dec/ttusb_dec.c
@@ -314,7 +314,8 @@ static u16 crc16(u16 crc, const u8 *buf, size_t len)
 
 static int ttusb_dec_send_command(struct ttusb_dec *dec, const u8 command,
 				  int param_length, const u8 params[],
-				  int *result_length, u8 cmd_result[])
+				  int *result_length, u8 cmd_result[],
+				  int cmd_result_size)
 {
 	int result, actual_len;
 	u8 *b;
@@ -366,10 +367,24 @@ static int ttusb_dec_send_command(struct ttusb_dec *dec, const u8 command,
 			       __func__, actual_len, b);
 		}
 
-		if (result_length)
-			*result_length = b[3];
-		if (cmd_result && b[3] > 0)
-			memcpy(cmd_result, &b[4], b[3]);
+		if (result_length) {
+			int copy_len = b[3];
+
+			/* The reply length byte is controlled by the device
+			 * and may not match the data actually received, so
+			 * bound the copy to the received payload as well as
+			 * to the caller's buffer.
+			 */
+			if (actual_len > 4)
+				copy_len = min(copy_len, actual_len - 4);
+			else
+				copy_len = 0;
+			if (cmd_result)
+				copy_len = min(copy_len, cmd_result_size);
+			*result_length = copy_len;
+			if (cmd_result && copy_len > 0)
+				memcpy(cmd_result, &b[4], copy_len);
+		}
 	}
 
 err_mutex_unlock:
@@ -389,7 +404,8 @@ static int ttusb_dec_get_stb_state (struct ttusb_dec *dec, unsigned int *mode,
 
 	dprintk("%s\n", __func__);
 
-	result = ttusb_dec_send_command(dec, 0x08, 0, NULL, &c_length, c);
+	result = ttusb_dec_send_command(dec, 0x08, 0, NULL, &c_length, c,
+					sizeof(c));
 	if (result)
 		return result;
 
@@ -448,7 +464,7 @@ static void ttusb_dec_set_pids(struct ttusb_dec *dec)
 	memcpy(&b[2], &audio, 2);
 	memcpy(&b[4], &video, 2);
 
-	ttusb_dec_send_command(dec, 0x50, sizeof(b), b, NULL, NULL);
+	ttusb_dec_send_command(dec, 0x50, sizeof(b), b, NULL, NULL, 0);
 
 	dvb_filter_pes2ts_init(&dec->a_pes2ts, dec->pid[DMX_PES_AUDIO],
 			       ttusb_dec_audio_pes2ts_cb, dec);
@@ -902,7 +918,7 @@ static int ttusb_dec_set_interface(struct ttusb_dec *dec,
 			break;
 		case TTUSB_DEC_INTERFACE_IN:
 			result = ttusb_dec_send_command(dec, 0x80, sizeof(b),
-							b, NULL, NULL);
+							b, NULL, NULL, 0);
 			if (result)
 				return result;
 			result = usb_set_interface(dec->udev, 0, 8);
@@ -1021,7 +1037,7 @@ static int ttusb_dec_start_ts_feed(struct dvb_demux_feed *dvbdmxfeed)
 
 	}
 
-	result = ttusb_dec_send_command(dec, 0x80, sizeof(b0), b0, NULL, NULL);
+	result = ttusb_dec_send_command(dec, 0x80, sizeof(b0), b0, NULL, NULL, 0);
 	if (result)
 		return result;
 
@@ -1056,7 +1072,7 @@ static int ttusb_dec_start_sec_feed(struct dvb_demux_feed *dvbdmxfeed)
 	memcpy(&b0[5], &dvbdmxfeed->filter->filter.filter_value[0], 1);
 
 	result = ttusb_dec_send_command(dec, 0x60, sizeof(b0), b0,
-					&c_length, c);
+					&c_length, c, sizeof(c));
 
 	if (!result) {
 		if (c_length == 2) {
@@ -1114,7 +1130,7 @@ static int ttusb_dec_stop_ts_feed(struct dvb_demux_feed *dvbdmxfeed)
 	struct ttusb_dec *dec = dvbdmxfeed->demux->priv;
 	u8 b0[] = { 0x00 };
 
-	ttusb_dec_send_command(dec, 0x81, sizeof(b0), b0, NULL, NULL);
+	ttusb_dec_send_command(dec, 0x81, sizeof(b0), b0, NULL, NULL, 0);
 
 	dec->pva_stream_count--;
 
@@ -1135,7 +1151,7 @@ static int ttusb_dec_stop_sec_feed(struct dvb_demux_feed *dvbdmxfeed)
 	list_del(&finfo->filter_info_list);
 	spin_unlock_irqrestore(&dec->filter_info_list_lock, flags);
 	kfree(finfo);
-	ttusb_dec_send_command(dec, 0x62, sizeof(b0), b0, NULL, NULL);
+	ttusb_dec_send_command(dec, 0x62, sizeof(b0), b0, NULL, NULL, 0);
 
 	dec->filter_stream_count--;
 
@@ -1238,7 +1254,7 @@ static int ttusb_init_rc( struct ttusb_dec *dec)
 	if (usb_submit_urb(dec->irq_urb, GFP_KERNEL))
 		printk("%s: usb_submit_urb failed\n",__func__);
 	/* enable irq pipe */
-	ttusb_dec_send_command(dec,0xb0,sizeof(b),b,NULL,NULL);
+	ttusb_dec_send_command(dec, 0xb0, sizeof(b), b, NULL, NULL, 0);
 
 	return 0;
 }
@@ -1354,7 +1370,7 @@ static int ttusb_dec_boot_dsp(struct ttusb_dec *dec)
 	firmware_csum_ns = htons(firmware_csum);
 	memcpy(&b0[6], &firmware_csum_ns, 2);
 
-	result = ttusb_dec_send_command(dec, 0x41, sizeof(b0), b0, NULL, NULL);
+	result = ttusb_dec_send_command(dec, 0x41, sizeof(b0), b0, NULL, NULL, 0);
 
 	if (result) {
 		release_firmware(fw_entry);
@@ -1395,7 +1411,7 @@ static int ttusb_dec_boot_dsp(struct ttusb_dec *dec)
 		}
 	}
 
-	result = ttusb_dec_send_command(dec, 0x43, sizeof(b1), b1, NULL, NULL);
+	result = ttusb_dec_send_command(dec, 0x43, sizeof(b1), b1, NULL, NULL, 0);
 
 	release_firmware(fw_entry);
 	kfree(b);
@@ -1621,10 +1637,13 @@ static void ttusb_dec_exit_filters(struct ttusb_dec *dec)
 
 static int fe_send_command(struct dvb_frontend* fe, const u8 command,
 			   int param_length, const u8 params[],
-			   int *result_length, u8 cmd_result[])
+			   int *result_length, u8 cmd_result[],
+			   int cmd_result_size)
 {
 	struct ttusb_dec* dec = fe->dvb->priv;
-	return ttusb_dec_send_command(dec, command, param_length, params, result_length, cmd_result);
+	return ttusb_dec_send_command(dec, command, param_length, params,
+				      result_length, cmd_result,
+				      cmd_result_size);
 }
 
 static const struct ttusbdecfe_config fe_config = {
diff --git a/drivers/media/usb/ttusb-dec/ttusbdecfe.c b/drivers/media/usb/ttusb-dec/ttusbdecfe.c
index 215221370c1..b013d6dfcbe 100644
--- a/drivers/media/usb/ttusb-dec/ttusbdecfe.c
+++ b/drivers/media/usb/ttusb-dec/ttusbdecfe.c
@@ -44,7 +44,8 @@ static int ttusbdecfe_dvbt_read_status(struct dvb_frontend *fe,
 
 	*status=0;
 
-	ret=state->config->send_command(fe, 0x73, sizeof(b), b, &len, result);
+	ret = state->config->send_command(fe, 0x73, sizeof(b), b, &len, result,
+					  sizeof(result));
 	if(ret)
 		return ret;
 
@@ -85,7 +86,7 @@ static int ttusbdecfe_dvbt_set_frontend(struct dvb_frontend *fe)
 
 	__be32 freq = htonl(p->frequency / 1000);
 	memcpy(&b[4], &freq, sizeof (u32));
-	state->config->send_command(fe, 0x71, sizeof(b), b, NULL, NULL);
+	state->config->send_command(fe, 0x71, sizeof(b), b, NULL, NULL, 0);
 
 	return 0;
 }
@@ -130,7 +131,7 @@ static int ttusbdecfe_dvbs_set_frontend(struct dvb_frontend *fe)
 	lnb_voltage = htonl(state->voltage);
 	memcpy(&b[28], &lnb_voltage, sizeof(u32));
 
-	state->config->send_command(fe, 0x71, sizeof(b), b, NULL, NULL);
+	state->config->send_command(fe, 0x71, sizeof(b), b, NULL, NULL, 0);
 
 	return 0;
 }
@@ -149,7 +150,7 @@ static int ttusbdecfe_dvbs_diseqc_send_master_cmd(struct dvb_frontend* fe, struc
 
 	state->config->send_command(fe, 0x72,
 				    sizeof(b) - (6 - cmd->msg_len), b,
-				    NULL, NULL);
+				    NULL, NULL, 0);
 
 	return 0;
 }
diff --git a/drivers/media/usb/ttusb-dec/ttusbdecfe.h b/drivers/media/usb/ttusb-dec/ttusbdecfe.h
index 73828bb2258..3ccb42977d8 100644
--- a/drivers/media/usb/ttusb-dec/ttusbdecfe.h
+++ b/drivers/media/usb/ttusb-dec/ttusbdecfe.h
@@ -14,7 +14,8 @@ struct ttusbdecfe_config
 {
 	int (*send_command)(struct dvb_frontend* fe, const u8 command,
 			    int param_length, const u8 params[],
-			    int *result_length, u8 cmd_result[]);
+			    int *result_length, u8 cmd_result[],
+			    int cmd_result_size);
 };
 
 extern struct dvb_frontend* ttusbdecfe_dvbs_attach(const struct ttusbdecfe_config* config);

---
base-commit: 075b74841bd0065a3bda3440873c747938e69b68
change-id: 20260803-fix-ttusb-dec-cmd-result-overflow-7b7b72bc5f44

Best regards,
--  
Anuj Bolewar <bolewara@gmail.com>

