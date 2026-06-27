/**
 * Curated Nashik emergency support points used when OSM/Authority DB is empty.
 * Coordinates are approximate city-center references for Nashik district.
 */
const nashikAuthorityBaseline = [
  {
    name: 'Nashik City Police Commissioner Office',
    authorityType: 'police',
    phone: '100',
    address: 'Shahid Chowk, Nashik',
    coordinates: [73.7898, 19.9975],
  },
  {
    name: 'Nashik Road Police Station',
    authorityType: 'police',
    phone: '100',
    address: 'Nashik Road, Nashik',
    coordinates: [73.839, 19.948],
  },
  {
    name: 'CIDCO Police Station',
    authorityType: 'police',
    phone: '100',
    address: 'CIDCO, Nashik',
    coordinates: [73.748, 20.008],
  },
  {
    name: 'Satpur Police Station',
    authorityType: 'police',
    phone: '100',
    address: 'Satpur MIDC, Nashik',
    coordinates: [73.728, 19.997],
  },
  {
    name: 'Civil Hospital Nashik',
    authorityType: 'hospital',
    phone: '108',
    address: 'Panchavati, Nashik',
    coordinates: [73.789, 19.988],
  },
  {
    name: 'Wockhardt Hospital Nashik',
    authorityType: 'hospital',
    phone: '108',
    address: 'Nashik',
    coordinates: [73.768, 20.011],
  },
  {
    name: 'Suyash Hospital',
    authorityType: 'hospital',
    phone: '108',
    address: 'Gangapur Road, Nashik',
    coordinates: [73.756, 20.018],
  },
];

module.exports = { nashikAuthorityBaseline };
