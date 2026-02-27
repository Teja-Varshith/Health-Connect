import express from "express";
import twilio from "twilio";

const app = express();

const accountSid = process.env.TWILIO_SID;
const authToken = process.env.TWILIO_AUTH;
const client = twilio(accountSid, authToken);

app.post("/send-whatsapp", async (req, res) => {
  try {
    await client.messages.create({
      to: "whatsapp:+918688153143",
      from: "whatsapp:+14155238886",
      contentSid: "HXb5b62575e6e4ff6129ad7c8efe1f983e",
      contentVariables: JSON.stringify({
        1: "12/1",
        2: "3pm"
      })
    });

    res.send("Message sent");
  } catch (err) {
    res.status(500).send(err.message);
  }
});

app.listen(3000);