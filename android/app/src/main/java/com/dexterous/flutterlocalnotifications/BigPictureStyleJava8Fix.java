package com.dexterous.flutterlocalnotifications;

import android.app.Notification;
import android.graphics.Bitmap;

public class BigPictureStyleJava8Fix {
    public static void setBigLargeIconNull(Notification.BigPictureStyle bigPictureStyle) {
        bigPictureStyle.bigLargeIcon((Bitmap)null);
    }
}