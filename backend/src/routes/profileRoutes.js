const express = require('express');
const { authGuard } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const {
  upload,
  getProfile,
  updateProfile,
  addContact,
  listContacts,
  updateContact,
  deleteContact,
  uploadProfilePhoto,
  updateProfileSchema,
  contactSchema,
  updateContactSchema,
  deleteContactSchema,
  fcmTokenSchema,
  registerFcmToken,
} = require('../controllers/profileController');
const router = express.Router();
router.get('/', authGuard, getProfile);
router.patch('/', authGuard, validate(updateProfileSchema), updateProfile);
router.post('/photo', authGuard, upload.single('file'), uploadProfilePhoto);
router.post('/fcm-token', authGuard, validate(fcmTokenSchema), registerFcmToken);
router.get('/contacts', authGuard, listContacts);
router.post('/contacts', authGuard, validate(contactSchema), addContact);
router.patch('/contacts/:id', authGuard, validate(updateContactSchema), updateContact);
router.delete('/contacts/:id', authGuard, validate(deleteContactSchema), deleteContact);
module.exports = router;
