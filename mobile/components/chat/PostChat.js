import React, { Component } from 'react'
import { Text, View, TextInput } from 'react-native'
import {Socket} from "phoenix"
import { get } from '../../lib/fetcher'
import { GiftedChat } from 'react-native-gifted-chat'

class PostChat extends Component {
  static defaultProps = {
    id: 1
  }

  constructor(props) {
    super(props)
    this.state = {
      messages: [
        {
          _id: 1,
          text: 'Hello developer',
          createdAt: new Date(Date.UTC(2016, 7, 30, 17, 20, 0)),
          user: {
            _id: 1,
            name: 'React Native',
            avatar: 'https://facebook.github.io/react/img/logo_og.png',
          },
        }
      ]
    }
  }

  setUpChat() {
    const socket = new Socket("https://stormy-reef-53700.herokuapp.com/socket",)
		const roomId = `room:${this.props.id}`

    socket.connect()
    this.channel = socket.channel(roomId, {})

    this.channel.on("new_msg", payload => {
      const newMsg = this.state.messages.concat([{body: payload.body}])
      this.setState({messages: newMsg})
    })

    this.channel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", resp => { console.log("Unable to join", resp) })
  }

  getMessages() {
    const cb = (resp) => {
      this.setState({foo: "bar"})
    }

    get('/posts/1/messages').then(cb)
  }

  componentDidMount() {
    this.getMessages()
    this.setUpChat()
  }

  componentWillUnmount() {
    this.channel.leave()
  }

  onSend = (messages = []) => {
    alert(messages)
    this.channel.push("new_msg", {body: "testing testing", post_id: this.props.id})
    this.setState({text: ''})
  }

  onSend = (messages = []) => {
    this.setState((previousState) => {
      return {
        messages: GiftedChat.append(previousState.messages, messages),
      }
    })
  }

  render() {
    return (
      <GiftedChat
        messages={this.state.messages}
        onSend={this.onSend}
        user={{_id: 1}}
      />
    )
  }
}

export default PostChat