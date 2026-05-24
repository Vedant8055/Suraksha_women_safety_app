const toPoint = (lat, lng) => ({ type: 'Point', coordinates: [Number(lng), Number(lat)] });
module.exports = { toPoint };
