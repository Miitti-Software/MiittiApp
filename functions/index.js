import {onObjectFinalized} from "firebase-functions/v2/storage";
import {onCall} from "firebase-functions/v2/https";
import {onDocumentDeleted} from "firebase-functions/v2/firestore";
import {initializeApp} from "firebase-admin/app";
import {getStorage} from "firebase-admin/storage";
import {getMessaging} from "firebase-admin/messaging";
import sharp from "sharp";
import path from "path";
import os from "os";
import fs from "fs";

initializeApp();

const region = "europe-west1"; // Specify the region of your storage bucket

exports.generateThumbnail = onObjectFinalized({region}, async (event) => {
  const object = event.data;
  const filePath = object.name;
  const contentType = object.contentType;
  const fileName = path.basename(filePath);
  const tempFilePath = path.join(os.tmpdir(), fileName);
  const thumbFilePath = path.join(path.dirname(filePath), `thumb_${fileName}`);
  const tempThumbFilePath = path.join(os.tmpdir(), `thumb_${fileName}`);

  if (!contentType.endsWith(".jpg")) {
    console.log("This is not an image.");
    return;
  }

  if (fileName.startsWith("thumb_")) {
    console.log("Already a Thumbnail.");
    return;
  }

  await getStorage()
    .bucket(object.bucket)
    .file(filePath)
    .download({destination: tempFilePath});
  console.log("Image downloaded locally to", tempFilePath);

  await sharp(tempFilePath).resize(200, 200).toFile(tempThumbFilePath);
  console.log("Thumbnail created at", tempThumbFilePath);

  await getStorage()
    .bucket(object.bucket)
    .upload(tempThumbFilePath, {
      destination: thumbFilePath,
      metadata: {contentType},
    });
  console.log("Thumbnail uploaded to", thumbFilePath);

  fs.unlinkSync(tempFilePath);
  fs.unlinkSync(tempThumbFilePath);
});

exports.sendNotificationTo = onCall({region}, async (data) => {
  const notification = {
    token: data.receiver,
    notification: {
      body: data.message,
      title: data.title,
    },
    data: {
      type: data.type,
      myData: data.myData,
    },
  };

  try {
    const response = await getMessaging().send(notification);
    return response;
  } catch (error) {
    console.error("Error sending notification:", error);
    throw new onCall.HttpsError("internal", "Error sending notification");
  }
});

exports.userDeleted = onDocumentDeleted(
  {region},
  "activities/{activityId}",
  async (event) => {
    const snapshot = event.data;
    const docText = JSON.stringify(snapshot.data());

    const bucket = getStorage().bucket();
    const file = bucket.file(`deletedActivities/${snapshot.id}.json`);

    try {
      await file.save(docText);
      console.log("Deleted activity copied");
    } catch (error) {
      console.log("Error copying deleted activity", error);
    }
  }
);
