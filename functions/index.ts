import {onObjectFinalized, StorageEvent} from "firebase-functions/v2/storage";
// import {CloudEvent} from "cloudevents";
// import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
// import {onDocumentDeleted} from "firebase-functions/v2/firestore";
// import {initializeApp} from "firebase-admin/app";
import {getStorage} from "firebase-admin/storage";
// import {getMessaging} from "firebase-admin/messaging";
import * as admin from 'firebase-admin';
import sharp from "sharp";
import path from "path";
import os from "os";
import fs from "fs";

// Initialize the Firebase Admin SDK
admin.initializeApp();

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

// Generate a thumbnail when an image is uploaded
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
      await sharp(tempFilePath)
        .rotate()
        .resize({ width: 150, height: 150, fit: "outside" })
        .jpeg({ quality: 75 })
        .toFile(tempThumbFilePath);
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

import { onRequest } from "firebase-functions/v2/https";

export const batchProcessImages = onRequest(async (req, res) => {
  const bucket = admin.storage().bucket();
  
  try {
    // List all files in the bucket
    const [files] = await bucket.getFiles();
    
    for (const file of files) {
      const filePath = file.name;
      const contentType = file.metadata.contentType;
      
      // Skip non-JPEG images
      if (!contentType || (!contentType.endsWith('jpeg') && !contentType.endsWith('jpg'))) {
        console.log(`Skipping non-JPEG file: ${filePath}`);
        continue;
      }
      
      // Skip existing thumbnails
      if (path.basename(filePath).startsWith('thumb_')) {
        console.log(`Skipping thumbnail: ${filePath}`);
        continue;
      }
      
      const fileName = path.basename(filePath);
      const tempFilePath = path.join(os.tmpdir(), fileName);
      const thumbFileName = `thumb_${fileName}`;
      const thumbFilePath = path.join(path.dirname(filePath), thumbFileName);
      const tempThumbFilePath = path.join(os.tmpdir(), thumbFileName);
      const tempCompressedFilePath = path.join(os.tmpdir(), `temp_${fileName}`);
      
      try {
        // Download the image
        await file.download({ destination: tempFilePath });
        console.log(`Downloaded ${filePath} to ${tempFilePath}`);
        
        // Compress and resize the original image
        await sharp(tempFilePath)
          .rotate()
          .resize({ width: 1024, height: 1024, fit: 'inside' })
          .jpeg({ quality: 75 })
          .toFile(tempCompressedFilePath);
        console.log(`Compressed image created at ${tempCompressedFilePath}`);
        
        // Generate a thumbnail
        await sharp(tempCompressedFilePath)
          .rotate()
          .resize({ width: 150, height: 150, fit: 'outside' })
          .jpeg({ quality: 75 })
          .toFile(tempThumbFilePath);
        console.log(`Thumbnail created at ${tempThumbFilePath}`);
        
        // Upload the compressed image (replacing the original)
        await bucket.upload(tempCompressedFilePath, {
          destination: filePath,
          metadata: { contentType: 'image/jpeg' },
        });
        console.log(`Compressed image uploaded, replacing ${filePath}`);
        
        // Upload the thumbnail
        await bucket.upload(tempThumbFilePath, {
          destination: thumbFilePath,
          metadata: { contentType: 'image/jpeg' },
        });
        console.log(`Thumbnail uploaded to ${thumbFilePath}`);
      } catch (error) {
        console.error(`Error processing file ${filePath}:`, error);
      } finally {
        // Clean up temporary files
        [tempFilePath, tempCompressedFilePath, tempThumbFilePath].forEach((path) => {
          if (fs.existsSync(path)) {
            fs.unlinkSync(path);
          }
        });
      }
    }
    
    res.status(200).send('Batch image processing completed successfully.');
  } catch (error) {
    console.error('Error in batch processing:', error);
    res.status(500).send('An error occurred during batch processing.');
  }
});

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

