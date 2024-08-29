import {onObjectFinalized, StorageEvent} from "firebase-functions/v2/storage";
// import {CloudEvent} from "cloudevents";
// import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
// import {onDocumentDeleted} from "firebase-functions/v2/firestore";
import {initializeApp} from "firebase-admin/app";
import {getStorage} from "firebase-admin/storage";
// import {getMessaging} from "firebase-admin/messaging";
import sharp from "sharp";
import path from "path";
import os from "os";
import fs from "fs";

// Initialize the Firebase Admin SDK
initializeApp();

const region = "europe-west1";

// Define interfaces for event data
// interface StorageObjectData {
//   name?: string;
//   contentType?: string;
//   bucket: string;
// }

// interface NotificationData {
//   receiver: string;
//   message: string;
//   title: string;
//   type?: string;
//   myData?: string;
// }

exports.generateThumbnail = onObjectFinalized(
  {region},
  async (event: StorageEvent) => {
    const object = event.data;

    const filePath = object.name;
    const contentType = object.contentType;

    // Validate the required fields
    if (!filePath || !contentType) {
      console.log("File path or content type is missing.");
      return;
    }

    const fileName = path.basename(filePath);
    const tempFilePath = path.join(os.tmpdir(), fileName);
    const thumbFileName = `thumb_${fileName}`;
    const thumbFilePath = path.join(path.dirname(filePath), thumbFileName);
    const tempThumbFilePath = path.join(os.tmpdir(), thumbFileName);

    // Only process JPEG images
    if (!contentType.endsWith("jpeg") && !contentType.endsWith("jpg")) {
      console.log("This is not a JPEG image.");
      return;
    }

    // Skip if the file is already a thumbnail
    if (fileName.startsWith("thumb_")) {
      console.log("File is already a thumbnail.");
      return;
    }

    try {
      // Download the image from Cloud Storage
      await getStorage().bucket(object.bucket).file(filePath)
        .download({destination: tempFilePath});
      console.log("Image downloaded locally to", tempFilePath);

      // Generate a thumbnail using sharp
      await sharp(tempFilePath).resize(200, 200).toFile(tempThumbFilePath);
      console.log("Thumbnail created at", tempThumbFilePath);

      // Upload the thumbnail back to Cloud Storage
      await getStorage().bucket(object.bucket).upload(tempThumbFilePath, {
        destination: thumbFilePath,
        metadata: {contentType},
      });
      console.log("Thumbnail uploaded to", thumbFilePath);
    } catch (error) {
      console.error("Error processing file:", error);
    } finally {
      // Clean up temporary files
      if (fs.existsSync(tempFilePath)) {
        fs.unlinkSync(tempFilePath);
      }
      if (fs.existsSync(tempThumbFilePath)) {
        fs.unlinkSync(tempThumbFilePath);
      }
    }
  }
);

// exports.sendNotificationTo = onCall({region}, async (data: CallableRequest<NotificationData>) => {
//     const notification = {
//       token: data.data.receiver,
//       notification: {
//         body: data.data.message,
//         title: data.data.title,
//       },
//       data: {
//         ...data.data,
//       },
//     };
  
//     try {
//       const response = await getMessaging().send(notification);
//       return response;
//     } catch (error) {
//       console.error("Error sending notification:", error);
//       throw new HttpsError("internal", "Error sending notification");
//     }
//   });

// exports.userDeleted = onDocumentDeleted(
//   {region},
//   "activities/{activityId}",
//   async (event) => {
//     const snapshot = event.data;

//     if (!snapshot) {
//       console.error("No data snapshot found.");
//       return;
//     }

//     const docText = JSON.stringify(snapshot.data());

//     const bucket = getStorage().bucket();
//     const file = bucket.file(`deletedActivities/${snapshot.id}.json`);

//     try {
//       await file.save(docText);
//       console.log("Deleted activity copied to Cloud Storage");
//     } catch (error) {
//       console.error("Error copying deleted activity to Cloud Storage:",
//          error);
//     }
//   }
// );

