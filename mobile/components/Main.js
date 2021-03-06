import React, { Component } from 'react'
import {
  View,
  Text
} from 'react-native'
import { connect } from 'react-redux'
import { AppLoading } from 'expo'

import {
  authActions,
  loadInitialAuth,
  currentUserSeenIntro,
  loadIntroCheck
} from '../data/auth'

import LoginOrSignUp from './user/LoginOrSignUp'
import MainNav from './navigation/MainNav'
// import Intro from './intro/Intro'

// =============
//   PRESENTER
// =============

class Main extends Component {
  componentDidMount(){
    this.props.loadIntroCheck()
    this.props.loadInitialAuth()
  }

  renderLoading () {
    return <AppLoading />
  }

  renderLogin () {
    return <LoginOrSignUp />
  }

  renderMainApp () {
    return <MainNav />
  }

  // renderWalkThru () {
  //   return <Intro onIntroDone={this.props.onIntroDone} />
  // }

  render () {
    if (this.props.isLoading) {
      return this.renderLoading()
    }

    if (!this.props.jwt) {
      return this.renderLogin()
    }

    // if (!this.props.introSeen) {
    //   return this.renderWalkThru()
    // }

    return this.renderMainApp()
  }
}

// ===============
//   CONNECTION
// ===============

const mapStateToProps = (state) => {
  return {
    jwt: state.auth.jwt,
    isLoading: !state.auth.initialStateLoaded,
    introSeen: currentUserSeenIntro(state.auth)
  }
}

export default connect(
  mapStateToProps,
  { loadInitialAuth, loadIntroCheck, onIntroDone: authActions.onIntroDone }
)(Main)
